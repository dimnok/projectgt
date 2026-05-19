import { Webhook } from 'https://esm.sh/standardwebhooks@1.0.0'

const NOTISEND_API_KEY = Deno.env.get('NOTISEND_API_KEY')
const NOTISEND_PROJECT = Deno.env.get('NOTISEND_PROJECT')
const SEND_SMS_HOOK_SECRET = Deno.env.get('SEND_SMS_HOOK_SECRET')

/** Тестовый номер: SMS не отправляется (OTP задаётся в GoTrue через GOTRUE_SMS_TEST_OTP). */
const TEST_PHONE_E164 = '+70000000000'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, webhook-id, webhook-timestamp, webhook-signature',
}

const normalizeDigits = (phone: string) =>
  phone.replace(/\D/g, '').replace(/^8/, '7')

async function sendNotisendSms(phoneE164: string, message: string) {
  const cleanPhone = normalizeDigits(phoneE164)
  if (cleanPhone === '70000000000') {
    console.log('[auth-send-sms] test phone: SMS skipped')
    return
  }

  const params = new URLSearchParams({
    project: NOTISEND_PROJECT!,
    apikey: NOTISEND_API_KEY!,
    recipients: cleanPhone,
    message,
  })

  const url = `https://sms.notisend.ru/api/message/send?${params.toString()}`
  const res = await fetch(url, { method: 'GET', headers: { Accept: 'application/json' } })
  const result = (await res.json()) as Record<string, unknown>
  console.log('[auth-send-sms] Notisend:', JSON.stringify(result))

  if (result.status !== 'success') {
    throw new Error(`Notisend: ${String(result.message ?? JSON.stringify(result))}`)
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (!SEND_SMS_HOOK_SECRET?.startsWith('v1,whsec_')) {
    console.error('[auth-send-sms] SEND_SMS_HOOK_SECRET is not configured')
    return new Response(JSON.stringify({ error: 'Hook secret not configured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const payload = await req.text()
  const headers = Object.fromEntries(req.headers)
  const base64Secret = SEND_SMS_HOOK_SECRET.replace('v1,whsec_', '')
  const wh = new Webhook(base64Secret)

  try {
    const { user, sms } = wh.verify(payload, headers) as {
      user: { phone?: string }
      sms: { otp: string }
    }

    const phone = user?.phone?.trim()
    const otp = sms?.otp?.trim()

    if (!phone || !otp) {
      throw new Error('Missing phone or otp in hook payload')
    }

    if (phone !== TEST_PHONE_E164) {
      await sendNotisendSms(phone, `Код подтверждения: ${otp}`)
    }

    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    console.error('[auth-send-sms] error:', message)
    return new Response(
      JSON.stringify({
        error: {
          http_code: 500,
          message: `Failed to send SMS: ${message}`,
        },
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )
  }
})
