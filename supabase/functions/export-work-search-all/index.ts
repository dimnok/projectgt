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

    const client = createClient(supabaseUrl, supabaseKey);

    if (!requestData.objectId) {
      return new Response(JSON.stringify({
        success: false,
        message: "objectId is required"
      }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Используем RPC функцию search_work_items_paginated для получения ВСЕХ данных
    const { data, error } = await client.rpc('search_work_items_paginated', {
      p_object_id: requestData.objectId,
      p_start_date: requestData.startDate || null,
      p_end_date: requestData.endDate || null,
      p_system_filters: (requestData.systemFilters?.length ?? 0) > 0 ? requestData.systemFilters : null,
      p_section_filters: (requestData.sectionFilters?.length ?? 0) > 0 ? requestData.sectionFilters : null,
      p_floor_filters: (requestData.floorFilters?.length ?? 0) > 0 ? requestData.floorFilters : null,
      p_search_query: requestData.searchQuery || null,
      p_from: 0,
      p_to: 100000 
    });

    if (error) {
      console.error("RPC Error:", error);
      throw error;
    }

    const results = (data || []).map((item: any) => {
      // Логируем для отладки (только если есть данные)
      if (item.m15_name) {
        // console.log(`Found m15_name: ${item.m15_name} for ${item.work_name}`);
      }
      
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
        m15_name: item.m15_name || "", // Используем snake_case для надежности
        m15Name: item.m15_name || "",  // И camelCase для совместимости
        unit: item.unit || "",
        quantity: Number(item.quantity) || 0,
        price: Number(item.price) || 0,
        total: (Number(item.price) || 0) * (Number(item.quantity) || 0)
      };
    });

    console.log(`Successfully processed ${results.length} records. First m15_name: ${results[0]?.m15_name || 'none'}`);

    return new Response(JSON.stringify({
      success: true,
      results: results,
      totalCount: results.length,
      message: `Loaded all ${results.length} records using RPC`
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
