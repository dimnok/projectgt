import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

Deno.serve(async (req: Request) => {
  // CORS для preflight запроса
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    })
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 })
  }

  try {
    const botToken = Deno.env.get("TELEGRAM_BOT_TOKEN_MINIAPP")
    if (!botToken) {
      return new Response(
        JSON.stringify({ error: "TELEGRAM_BOT_TOKEN_MINIAPP not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    const body = await req.json()
    const { initData } = body

    if (!initData || typeof initData !== "string") {
      return new Response(
        JSON.stringify({ error: "Missing or invalid initData" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    console.log("🔄 Verifying Telegram initData...")

    // Парсим initData (это URL query string)
    const params = new URLSearchParams(initData)
    const hash = params.get("hash")

    if (!hash) {
      return new Response(
        JSON.stringify({ error: "Missing hash in initData" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    // Создаём dataCheckString (все параметры кроме hash, отсортированные)
    const dataCheckArray: string[] = []
    params.forEach((value, key) => {
      if (key !== "hash") {
        dataCheckArray.push(`${key}=${value}`)
      }
    })
    const dataCheckString = dataCheckArray.sort().join("\n")

    console.log("📝 DataCheckString created")

    // Вычисляем HMAC-SHA256
    const encoder = new TextEncoder()

    // Шаг 1: HMAC('WebAppData', botToken)
    const secretKey = await crypto.subtle.importKey(
      "raw",
      encoder.encode("WebAppData"),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    )
    const secretBytes = await crypto.subtle.sign("HMAC", secretKey, encoder.encode(botToken))

    // Шаг 2: HMAC(secretBytes, dataCheckString)
    const signKey = await crypto.subtle.importKey(
      "raw",
      secretBytes,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    )
    const signature = await crypto.subtle.sign("HMAC", signKey, encoder.encode(dataCheckString))

    // Конвертируем в hex
    const signatureHex = Array.from(new Uint8Array(signature))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("")

    console.log(`✅ Computed signature: ${signatureHex.substring(0, 20)}...`)
    console.log(`📋 Expected hash: ${hash.substring(0, 20)}...`)

    // Сравниваем хеши
    if (signatureHex !== hash) {
      console.error("❌ Signature mismatch")
      return new Response(
        JSON.stringify({ error: "Invalid signature" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      )
    }

    console.log("✅ Signature verified")

    // Парсим user из initData
    const userJson = params.get("user")
    if (!userJson) {
      return new Response(
        JSON.stringify({ error: "Missing user in initData" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    const telegramUser = JSON.parse(userJson)
    const telegramId = telegramUser.id

    console.log(`👤 Telegram user ID: ${telegramId}`)

    // Инициализируем Supabase с service role
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    )

    // Ищем профиль по telegram_user_id
    const { data: profile, error: searchError } = await supabase
      .from("profiles")
      .select("id")
      .eq("telegram_user_id", telegramId)
      .maybeSingle()

    if (searchError) {
      console.error("🔍 Search error:", searchError)
      return new Response(
        JSON.stringify({ error: `Database search error: ${searchError.message}` }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    let userId: string
    const firstName = telegramUser.first_name || "User"
    const lastName = telegramUser.last_name || ""
    const fullName = `${firstName} ${lastName}`.trim()
    const email = `tg_${telegramId}@telegram.local`

    if (profile) {
      // Профиль уже существует
      userId = profile.id
      console.log(`✅ Existing user found: ${userId}`)
    } else {
      // Создаём нового пользователя
      console.log("🆕 Creating new user...")

      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email: email,
        email_confirm: true,
        user_metadata: {
          name: fullName,
          telegram_user_id: telegramId,
        },
      })

      if (authError || !authData.user) {
        console.error("❌ Auth creation error:", authError)
        return new Response(
          JSON.stringify({ error: `Failed to create user: ${authError?.message}` }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        )
      }

      userId = authData.user.id
      console.log(`✅ Auth user created: ${userId}`)

      // Создаём профиль
      const { error: profileError } = await supabase.from("profiles").insert({
        id: userId,
        email: email,
        full_name: fullName,
        telegram_user_id: telegramId,
        status: false,
        role: "user",
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })

      if (profileError) {
        console.error("❌ Profile creation error:", profileError)
        return new Response(
          JSON.stringify({ error: `Failed to create profile: ${profileError.message}` }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        )
      }

      console.log(`✅ Profile created for user: ${userId}`)
    }

    // Создаём сессию
    const { data: { session }, error: sessionError } = await supabase.auth.admin.createSession(userId)

    if (sessionError || !session) {
      console.error("❌ Session creation error:", sessionError)
      return new Response(
        JSON.stringify({ error: "Failed to create session" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    console.log("✅ Session created, returning token")

    return new Response(
      JSON.stringify({
        access_token: session.access_token,
        refresh_token: session.refresh_token,
        user_id: userId,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    )
  } catch (error) {
    console.error("❌ Function error:", error)
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    )
  }
})

