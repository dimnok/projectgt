import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const NOTISEND_API_KEY = Deno.env.get('NOTISEND_API_KEY')
const NOTISEND_PROJECT = Deno.env.get('NOTISEND_PROJECT')
const OTP_SECRET = Deno.env.get('OTP_SECRET') || 'secret'

/** Нормализованный тестовый номер (+7 000 000-00-00). Notisend не вызывается; код фиксированный. */
const TEST_OTP_PHONE = '70000000000'
const TEST_OTP_CODE = '000000'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const normalize = (p: string) => p.replace(/\D/g, '').replace(/^8/, '7')

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { action, phone, code, token } = await req.json()

    if (action === 'send') {
      const cleanPhone = normalize(phone)
      const generatedCode =
        cleanPhone === TEST_OTP_PHONE
          ? TEST_OTP_CODE
          : Math.floor(100000 + Math.random() * 900000).toString()

      let notisendDebug: Record<string, unknown> = { test_phone: true, skipped_sms: true }

      if (cleanPhone !== TEST_OTP_PHONE) {
        const params = new URLSearchParams({
          project: NOTISEND_PROJECT!,
          apikey: NOTISEND_API_KEY!,
          recipients: cleanPhone,
          message: `Код подтверждения: ${generatedCode}`,
        })

        const url = `https://sms.notisend.ru/api/message/send?${params.toString()}`

        const res = await fetch(url, {
          method: 'GET',
          headers: { 'Accept': 'application/json' },
        })

        const result = await res.json() as Record<string, unknown>
        console.log('Notisend response:', JSON.stringify(result))

        if (result.status !== 'success') {
          throw new Error(`Notisend Error: ${String(result.message ?? JSON.stringify(result))}`)
        }
        notisendDebug = result
      } else {
        console.log('[otp-notisend] test phone: SMS skipped, use fixed code')
      }

      const exp = Date.now() + 300000
      const payload = JSON.stringify({ phone: cleanPhone, code: generatedCode, exp })
      const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(OTP_SECRET), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'])
      const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload))
      const signature = Array.from(new Uint8Array(sig)).map(b => b.toString(16).padStart(2, '0')).join('')

      return new Response(JSON.stringify({
        success: true,
        token: btoa(payload) + '.' + signature,
        debug: notisendDebug,
      }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    if (action === 'verify') {
      const [pB64, signature] = token.split('.')
      const pStr = atob(pB64)
      const p = JSON.parse(pStr)
      const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(OTP_SECRET), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify'])
      const sigBytes = new Uint8Array(signature.match(/.{1,2}/g)!.map(b => parseInt(b, 16)))
      
      if (!(await crypto.subtle.verify('HMAC', key, sigBytes, new TextEncoder().encode(pStr))) || Date.now() > p.exp || p.code !== code) {
        throw new Error('Invalid or expired code')
      }

      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!, 
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
        { auth: { persistSession: false } }
      )
      
      // Ищем профиль по нормализованному номеру (в БД часто "+7 XXX XXX XX XX", в токене — только цифры)
      const { data: profileRows, error: profileError } = await supabase.rpc(
        'get_profile_for_otp_phone',
        { p_normalized: p.phone },
      )

      if (profileError) {
        console.error('Error fetching profile:', profileError)
        throw new Error('Internal error during profile lookup')
      }

      const profile =
        Array.isArray(profileRows) && profileRows.length > 0
          ? (profileRows[0] as { id: string; email: string | null; phone: string | null })
          : null
      
      const tempPassword = `t_${Math.random().toString(36).substring(2, 15)}_${Date.now()}`;
      let loginEmail: string;

      if (!profile) {
        // РЕГИСТРАЦИЯ НОВОГО ПОЛЬЗОВАТЕЛЯ
        console.log('Registering new user for phone:', p.phone);
        loginEmail = `${p.phone}@telegram.gt`;
        
        // 1. Создаем пользователя в Auth
        const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
          email: loginEmail,
          email_confirmed: true,
          password: tempPassword,
          user_metadata: { phone: p.phone }
        });

        if (createError) {
          console.error('Auth signup error:', createError)
          throw createError;
        }
        if (!newUser.user) throw new Error('Failed to create user');

        // 2. Обновляем профиль (созданный триггером handle_new_user)
        // Ставим status: true и approved_at, так как телефон уже проверен через OTP
        const { error: updateError } = await supabase.from('profiles').update({ 
          phone: p.phone,
          status: true,
          approved_at: new Date().toISOString()
        }).eq('id', newUser.user.id);

        if (updateError) {
          console.error('Profile update error:', updateError)
        }
      } else {
        // ВХОД СУЩЕСТВУЮЩЕГО ПОЛЬЗОВАТЕЛЯ
        console.log('Logging in existing user:', profile.id);
        loginEmail = profile.email || `${p.phone}@telegram.gt`;
        
        // Обновляем пароль и форсируем подтверждение email в Auth
        const { error: authUpdateError } = await supabase.auth.admin.updateUserById(profile.id, { 
          password: tempPassword,
          email_confirm: true 
        });

        if (authUpdateError) {
          console.error('Auth update error:', authUpdateError)
          throw authUpdateError
        }
      }

      return new Response(JSON.stringify({ 
        success: true, 
        temp_pass: tempPassword, 
        email: loginEmail 
      }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }
  } catch (e) {
    console.error('Function error:', e.message)
    return new Response(JSON.stringify({ success: false, error: e.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
