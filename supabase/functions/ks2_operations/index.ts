import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { action, contractId, periodTo, actNumber, actDate } = await req.json();

    if (!contractId) {
      throw new Error("contractId is required");
    }

    if (action === 'preview') {
        return await handlePreview(supabase, contractId, periodTo);
    } else if (action === 'create') {
        if (!actNumber || !actDate) throw new Error("actNumber and actDate are required for creation");
        return await handleCreate(supabase, contractId, periodTo, actNumber, actDate);
    } else {
        throw new Error("Invalid action. Use 'preview' or 'create'");
    }

  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function handlePreview(supabase: any, contractId: string, periodTo: string) {
    console.log(`Previewing KS-2 for contract ${contractId} until ${periodTo}`);
    const data = await calculateKs2Candidates(supabase, contractId, periodTo);
    
    return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
}

async function handleCreate(supabase: any, contractId: string, periodTo: string, actNumber: string, actDate: string) {
    console.log(`Creating KS-2 for contract ${contractId}`);
    
    // 1. Recalculate candidates to ensure consistency (double-check limits)
    const { candidates, totalAmount } = await calculateKs2Candidates(supabase, contractId, periodTo);

    if (candidates.length === 0) {
        throw new Error("No eligible work items found for KS-2");
    }

    const candidateIds = candidates.map((c: any) => c.id);

    // 2. Create Act
    // period_from is min date of items, period_to is max date of items or provided periodTo
    const dates = candidates.map((c: any) => new Date(c.date).getTime());
    const minDate = new Date(Math.min(...dates));
    const maxDate = new Date(Math.max(...dates));

    const { data: act, error: actError } = await supabase
        .from('ks2_acts')
        .insert({
            contract_id: contractId,
            number: actNumber,
            date: actDate,
            period_from: minDate.toISOString(),
            period_to: maxDate.toISOString(), // Or periodTo? Using actual max date is safer for facts.
            total_amount: totalAmount,
            status: 'draft'
        })
        .select()
        .single();

    if (actError) throw actError;

    // 3. Link items to Act
    const { error: updateError } = await supabase
        .from('work_items')
        .update({ ks2_id: act.id })
        .in('id', candidateIds);

    if (updateError) {
        // Rollback act creation if update fails (manual compensation since no transactions in HTTP)
        await supabase.from('ks2_acts').delete().eq('id', act.id);
        throw updateError;
    }

    return new Response(JSON.stringify({ success: true, actId: act.id, itemsCount: candidates.length }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
}

async function calculateKs2Candidates(supabase: any, contractId: string, periodTo: string) {
    // 1. Get all Estimates for Contract (Limits)
    const { data: estimates, error: estError } = await supabase
        .from('estimates')
        .select('id, quantity, unit, price')
        .eq('contract_id', contractId);
    
    if (estError) throw estError;

    // Map: estimate_id -> { limit, price }
    const estimateLimits = new Map();
    estimates.forEach((e: any) => {
        estimateLimits.set(e.id, { 
            limit: Number(e.quantity) || 0,
            price: Number(e.price) || 0
        });
    });

    // 2. Get Historical Usage (Items already closed in previous KS-2)
    const { data: closedItems, error: closedError } = await supabase
        .from('work_items')
        .select('estimate_id, quantity')
        .not('ks2_id', 'is', null) // Closed
        .in('estimate_id', estimates.map((e: any) => e.id));

    if (closedError) throw closedError;

    const closedUsage = new Map();
    closedItems.forEach((i: any) => {
        const current = closedUsage.get(i.estimate_id) || 0;
        closedUsage.set(i.estimate_id, current + Number(i.quantity));
    });

    // 3. Get Open Candidates (Items without KS-2, up to periodTo)
    // We sort by date to close oldest items first (FIFO)
    let query = supabase
        .from('work_items')
        .select(`
            id, 
            estimate_id, 
            quantity, 
            name, 
            unit, 
            price, 
            works!inner(date)
        `)
        .is('ks2_id', null)
        .in('estimate_id', estimates.map((e: any) => e.id));
    
    if (periodTo) {
        query = query.lte('works.date', periodTo);
    }
    
    const { data: openItems, error: openError } = await query.order('works(date)', { ascending: true });

    if (openError) throw openError;

    // 4. Filter Logic (The Vacuum)
    const candidates = [];
    const skipped = [];
    const currentUsage = new Map(); // Track usage within this generation session

    // Initialize current usage with closed usage
    estimateLimits.forEach((val, key) => {
        currentUsage.set(key, closedUsage.get(key) || 0);
    });

    let totalAmount = 0;

    for (const item of openItems) {
        const estId = item.estimate_id;
        const limitInfo = estimateLimits.get(estId);
        
        if (!limitInfo) {
            skipped.push({ ...item, reason: 'No estimate' });
            continue;
        }

        const limit = limitInfo.limit;
        const used = currentUsage.get(estId);
        const itemQty = Number(item.quantity);
        
        // Check if item fits
        // Strict atomic check: We only take the item if it fully fits or if we allow splitting (not implemented yet)
        // User asked for "Simple and Reliable". Atomic is simplest.
        // But what if we have a big item 100, and limit 99? It will hang forever.
        // However, usually daily reports are small.
        // Let's implement ATOMIC logic first.
        
        if (used + itemQty <= limit) {
            // Fits!
            const price = item.price || limitInfo.price || 0;
            const amount = itemQty * price;
            
            candidates.push({
                id: item.id,
                name: item.name,
                unit: item.unit,
                quantity: itemQty,
                price: price,
                amount: amount,
                date: item.works?.date
            });
            
            currentUsage.set(estId, used + itemQty);
            totalAmount += amount;
        } else {
            // Does not fit
            skipped.push({ 
                ...item, 
                reason: `Limit exceeded. Limit: ${limit}, Used: ${used}, Item: ${itemQty}` 
            });
        }
    }

    return {
        candidates,
        skipped,
        totalAmount,
        stats: {
            candidatesCount: candidates.length,
            skippedCount: skipped.length
        }
    };
}

