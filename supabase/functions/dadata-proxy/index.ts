import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const DADATA_API_KEY = Deno.env.get('DADATA_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { inn } = await req.json()
    if (!inn || !DADATA_API_KEY) throw new Error('Missing INN or API Key')

    const response = await fetch("https://suggestions.dadata.ru/suggestions/api/4_1/rs/findById/party", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": `Token ${DADATA_API_KEY}`,
      },
      body: JSON.stringify({ query: inn })
    })

    const result = await response.json()
    const suggestion = result.suggestions?.[0]
    
    if (!suggestion) {
      return new Response(JSON.stringify(null), { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    const data = suggestion.data
    const okvedCode = data.okved || ""
    let okvedName = ""

    if (data.okveds && data.okveds.length > 0) {
      const main = data.okveds.find((o: any) => o.main === true || o.main === "1") || data.okveds[0]
      okvedName = main.name || ""
    }

    if (!okvedName) {
      okvedName = data.okved_text || data.okved_name || ""
    }

    if (!okvedName && data.activities && data.activities.length > 0) {
      okvedName = data.activities[0].value || ""
    }

    const activity = okvedName ? `[${okvedCode}] ${okvedName}` : okvedCode

    const parsedData = {
      nameFull: data.name?.full_with_opf || data.name?.full || suggestion.value,
      nameShort: data.name?.short_with_opf || data.name?.short || suggestion.value,
      inn: data.inn,
      kpp: data.kpp,
      ogrn: data.ogrn,
      okpo: data.okpo,
      legalAddress: data.address?.value,
      directorName: data.management?.name,
      directorPosition: data.management?.post,
      activityDescription: activity,
      email: data.emails?.[0]?.value,
      phone: data.phones?.[0]?.value,
    }

    return new Response(JSON.stringify(parsedData), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })

  } catch (e) {
    return new Response(JSON.stringify({ success: false, error: e.message }), { 
      status: 400, 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }
})
