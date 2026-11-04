// ROAD TRIP 2027 — Flight status proxy for AeroDataBox via RapidAPI.
// Deploy as Supabase Edge Function "flight-lookup". Store AERODATABOX_RAPIDAPI_KEY
// in Supabase Edge Function Secrets; never in GitHub client configuration.
// Limit: only verified trip_members may query. Supabase's anonymous auth session counts.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const allowedOrigin = "https://mottikallus-sys.github.io";
const cors = {
  "Access-Control-Allow-Origin": allowedOrigin,
  "Access-Control-Allow-Headers": "authorization, apikey, x-client-info, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{
  status,headers:{"Content-Type":"application/json; charset=utf-8","Cache-Control":"no-store",...cors}
});
const txt=(x:unknown)=>typeof x==="string"?x:"";
const localTime=(obj:any)=>txt(obj?.local||obj?.utc||obj?.scheduledTime?.local||obj?.scheduledTime?.utc);
Deno.serve(async req=>{
  if(req.method==="OPTIONS")return new Response(null,{status:204,headers:cors});
  if(req.method!=="POST")return json({error:"METHOD_NOT_ALLOWED"},405);
  if(req.headers.get("origin") && req.headers.get("origin")!==allowedOrigin)return json({error:"ORIGIN_NOT_ALLOWED"},403);
  const bearer=req.headers.get("authorization")||"";
  if(!bearer.startsWith("Bearer "))return json({error:"SIGN_IN_REQUIRED"},401);
  const url=Deno.env.get("SUPABASE_URL"),anon=Deno.env.get("SUPABASE_ANON_KEY");
  if(!url||!anon)return json({error:"SUPABASE_CONFIG_MISSING"},503);
  const db=createClient(url,anon,{global:{headers:{Authorization:bearer}},auth:{persistSession:false,autoRefreshToken:false}});
  const {data:{user},error:userError}=await db.auth.getUser();
  if(userError||!user)return json({error:"SIGN_IN_REQUIRED"},401);
  const {data:member,error:memberError}=await db.from("trip_members").select("user_id").eq("user_id",user.id).maybeSingle();
  if(memberError||!member)return json({error:"MEMBERS_ONLY"},403);
  let payload:any;
  try{payload=await req.json()}catch{return json({error:"INVALID_REQUEST"},400)}
  const number=txt(payload?.flightNumber).replace(/[\s-]/g,"").toUpperCase();
  const date=txt(payload?.date);
  if(!/^[A-Z0-9]{2,3}\d{1,5}[A-Z]?$/.test(number)||!/^(20\d\d)-(0[1-9]|1[0-2])-([0-2]\d|3[01])$/.test(date))
    return json({error:"INVALID_FLIGHT_OR_DATE"},400);
  const key=Deno.env.get("AERODATABOX_RAPIDAPI_KEY");
  if(!key)return json({error:"PROVIDER_NOT_CONFIGURED"},503);
  const target=`https://aerodatabox.p.rapidapi.com/flights/number/${encodeURIComponent(number)}/${encodeURIComponent(date)}?withAircraftImage=false&withLocation=false`;
  try{
    const response=await fetch(target,{headers:{"X-RapidAPI-Key":key,"X-RapidAPI-Host":"aerodatabox.p.rapidapi.com","Accept":"application/json"},signal:AbortSignal.timeout(12000)});
    if(response.status===429)return json({error:"PROVIDER_RATE_LIMIT"},429);
    if(response.status===401||response.status===403)return json({error:"PROVIDER_CREDENTIALS_OR_PLAN"},503);
    if(response.status===404)return json({error:"FLIGHT_NOT_FOUND"},404);
    if(!response.ok)return json({error:"PROVIDER_UNAVAILABLE",providerStatus:response.status},502);
    const body=await response.json();
    const results=Array.isArray(body)?body:Array.isArray(body?.flights)?body.flights:body?[body]:[];
    const mapped=results.slice(0,12).map((x:any)=>({
      flightNumber:txt(x.number||x.flight?.iataNumber||number),
      airline:txt(x.airline?.name),
      status:txt(x.status||x.flightStatus),
      departureAirport:txt(x.departure?.airport?.iata||x.departure?.iataCode),
      departureTime:localTime(x.departure?.scheduledTime||x.departure?.scheduled||x.departure),
      departureEstimated:localTime(x.departure?.revisedTime||x.departure?.estimatedTime||x.departure?.estimated),
      departureTerminal:txt(x.departure?.terminal),
      departureGate:txt(x.departure?.gate),
      arrivalAirport:txt(x.arrival?.airport?.iata||x.arrival?.iataCode),
      arrivalTime:localTime(x.arrival?.scheduledTime||x.arrival?.scheduled||x.arrival),
      arrivalEstimated:localTime(x.arrival?.revisedTime||x.arrival?.estimatedTime||x.arrival?.estimated),
      arrivalTerminal:txt(x.arrival?.terminal),
      arrivalGate:txt(x.arrival?.gate),
    })).filter(x=>x.flightNumber);
    if(!mapped.length)return json({error:"FLIGHT_NOT_FOUND"},404);
    return json({source:"AeroDataBox",queriedAt:new Date().toISOString(),flightDate:date,results:mapped,
      note:"Provider coverage may include schedules only, especially ahead of departure. Times may be airport-local. Verify flight details with the airline."});
  }catch(_err){return json({error:"PROVIDER_TIMEOUT_OR_NETWORK"},502)}
});
