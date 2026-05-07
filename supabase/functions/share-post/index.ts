import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const url = new URL(req.url)
  const id = url.searchParams.get('id')
  
  if (!id) {
    return new Response("ID del post no encontrado", { status: 400 })
  }

  // Construimos el enlace profundo. 
  // Usamos una ruta absoluta para que sea más fácil de procesar en la app.
  const deepLink = `io.supabase.artistscottage://app/post/${id}`
  
  // Enviamos el redireccionamiento real (como hace Supabase Auth)
  return Response.redirect(deepLink, 307)
})