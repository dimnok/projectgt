import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info"
};

interface SearchAllRequest {
  objectId: string;
  startDate?: string;
  endDate?: string;
  searchQuery?: string;
  systemFilters?: string[];
  sectionFilters?: string[];
  floorFilters?: string[];
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }

  try {
    const requestData: SearchAllRequest = await req.json();

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing Supabase configuration");
    }

    const client = createClient(supabaseUrl, supabaseKey, { auth: { persistSession: false } });

    if (!requestData.objectId) {
      return new Response(JSON.stringify({
        success: false,
        message: "objectId is required"
      }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Реализуем цикл для получения ВСЕХ данных, обходя лимит в 1000 строк
    const allData: any[] = [];
    let from = 0;
    const batchSize = 1000;
    let hasMore = true;

    while (hasMore) {
      const to = from + batchSize - 1;
      
      const { data, error } = await client.rpc('search_work_items_paginated', {
        p_object_id: requestData.objectId,
        p_start_date: requestData.startDate || null,
        p_end_date: requestData.endDate || null,
        p_system_filters: (requestData.systemFilters?.length ?? 0) > 0 ? requestData.systemFilters : null,
        p_section_filters: (requestData.sectionFilters?.length ?? 0) > 0 ? requestData.sectionFilters : null,
        p_floor_filters: (requestData.floorFilters?.length ?? 0) > 0 ? requestData.floorFilters : null,
        p_search_query: requestData.searchQuery || null,
        p_from: from,
        p_to: to 
      });

      if (error) {
        console.error(`RPC Error at offset ${from}:`, error);
        throw error;
      }

      if (data && data.length > 0) {
        allData.push(...data);
        if (data.length < batchSize) {
          hasMore = false;
        } else {
          from += batchSize;
        }
      } else {
        hasMore = false;
      }

      // Защита от бесконечного цикла или слишком большого объема
      if (allData.length >= 100000) {
        hasMore = false;
      }
    }

    const results = allData.map((item: any) => {
      return {
        workDate: item.work_date,
        objectName: item.object_name || "Unknown",
        contractNumber: item.contract_number || "",
        system: item.system || "",
        subsystem: item.subsystem || "",
        section: item.section || "",
        floor: item.floor || "",
        positionNumber: item.position_number || "",
        workName: item.work_name || "",
        m15_name: item.m15_name || "",
        m15Name: item.m15_name || "",
        unit: item.unit || "",
        quantity: Number(item.quantity) || 0,
        price: Number(item.price) || 0,
        total: (Number(item.price) || 0) * (Number(item.quantity) || 0)
      };
    });

    return new Response(JSON.stringify({
      success: true,
      results: results,
      totalCount: results.length,
      message: `Loaded all ${results.length} records in batches`
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  } catch (error) {
    console.error("Error in export-work-search-all:", error);
    return new Response(JSON.stringify({
      success: false,
      message: error instanceof Error ? error.message : String(error)
    }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }
});
