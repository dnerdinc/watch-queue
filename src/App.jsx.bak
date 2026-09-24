import { useState, useEffect, useRef, useCallback } from "react";
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://xrpecvplexhyhuunmyiy.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_UaLWwGYsmVkztDpMJCmUXQ_AWQy0IGp";
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const TMDB_TOKEN = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjNTJmZGI5MjIxZDg2YmFjNWU2MGE2OTVhZGE1ZTA4ZCIsIm5iZiI6MTc3MzY0MDM1MC4wNzYsInN1YiI6IjY5Yjc5YTllYzM4MWM5NmI5MDVjYTM5OSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.1N4GhHBdjW5UHn-HW3V8WOdDYEEe-iFl5VzQbU8oQLI";

function cleanTitle(t){ return t.replace(/\s*\(\d{4}\)\s*$/, "").replace(/\s*(19|20)\d{2}\s*$/, "").replace(/\s*\((film|movie|series|TV series|video game|soundtrack)\)\s*$/i, "").trim(); }
function extractYear(t){ const m=t.match(/\((\d{4})\)$/); return m?m[1]:null; }

async function fetchTMDBPoster(filmOrTitle, size="w300") {
  const isObj = typeof filmOrTitle !== "string";
  const raw = isObj ? (filmOrTitle.tmdbQuery || filmOrTitle.t) : filmOrTitle;
  const title = cleanTitle(raw);
  const year = isObj ? extractYear(filmOrTitle.t) : extractYear(filmOrTitle);
  try {
    const headers = { Authorization:`Bearer ${TMDB_TOKEN}` };
    const yearParam = year ? `&year=${year}` : "";
    const r1 = await fetch(`https://api.themoviedb.org/3/search/movie?query=${encodeURIComponent(title)}&language=en-US&page=1${yearParam}`,{headers});
    const d1 = await r1.json();
    let path = d1.results?.find(r=>r.poster_path)?.poster_path;
    if (!path && year) {
      const r2 = await fetch(`https://api.themoviedb.org/3/search/movie?query=${encodeURIComponent(title)}&language=en-US&page=1`,{headers});
      const d2 = await r2.json();
      path = d2.results?.find(r=>r.poster_path)?.poster_path;
    }
    return path ? `https://image.tmdb.org/t/p/${size}${path}` : null;
  } catch(_){ return null; }
}

async function fetchTMDBBackdrop(filmOrTitle) {
  const isObj = typeof filmOrTitle !== "string";
  const raw = isObj ? (filmOrTitle.tmdbQuery || filmOrTitle.t) : filmOrTitle;
  const title = cleanTitle(raw);
  const year = isObj ? extractYear(filmOrTitle.t) : extractYear(filmOrTitle);
  try {
    const headers = { Authorization:`Bearer ${TMDB_TOKEN}` };
    const yearParam = year ? `&year=${year}` : "";
    const r1 = await fetch(`https://api.themoviedb.org/3/search/movie?query=${encodeURIComponent(title)}&language=en-US&page=1${yearParam}`,{headers});
    const d1 = await r1.json();
    const movie = d1.results?.[0];
    if (!movie) return null;

    // Fetch videos (trailers) alongside
    const r2 = await fetch(`https://api.themoviedb.org/3/movie/${movie.id}/videos?language=en-US`,{headers});
    const d2 = await r2.json();
    const trailer = d2.results?.find(v=>v.site==="YouTube" && v.type==="Trailer")
      || d2.results?.find(v=>v.site==="YouTube" && v.type==="Teaser")
      || d2.results?.find(v=>v.site==="YouTube");

    return {
      backdrop: movie.backdrop_path ? `https://image.tmdb.org/t/p/original${movie.backdrop_path}` : null,
      poster: movie.poster_path ? `https://image.tmdb.org/t/p/w500${movie.poster_path}` : null,
      id: movie.id,
      youtubeKey: trailer?.key || null,
    };
  } catch(_){ return null; }
}

async function fetchYouTubeTrailer(filmTitle) {
  // Construct YouTube search URL for the trailer
  const query = encodeURIComponent(`${filmTitle} official trailer`);
  return `https://www.youtube.com/results?search_query=${query}`;
}
const TMDB_PROVIDER_MAP = {
  8:   "netflix",
  9:   "prime",
  337: "disney",
  15:  "hulu",
  2:   "appletv",
  386: "peacock",
  531: "paramount",
  1899:"max",
  29:  "peacock",
  1825:"max",
  73:  "tubi",
  191: "kanopy",
  212: "hoopla",
  538: "plex",
  2077:"plex",
};

async function fetchWatchProviders(filmTitle) {
  try {
    const headers = { Authorization:`Bearer ${TMDB_TOKEN}` };
    const title = cleanTitle(filmTitle);
    const year = extractYear(filmTitle);
    const yearParam = year ? `&year=${year}` : "";
    const sr = await fetch(`https://api.themoviedb.org/3/search/movie?query=${encodeURIComponent(title)}&language=en-US&page=1${yearParam}`,{headers});
    const sd = await sr.json();
    const movieId = sd.results?.[0]?.id;
    if (!movieId) return null;
    const wr = await fetch(`https://api.themoviedb.org/3/movie/${movieId}/watch/providers`,{headers});
    const wd = await wr.json();
    const usProviders = wd.results?.US;
    const jwLink = usProviders?.link || `https://www.justwatch.com/us/search?q=${encodeURIComponent(cleanTitle(filmTitle))}`;
    if (!usProviders) return { jwLink, platforms: {} };

    const allProviders = [
      ...(usProviders.flatrate || []),
      ...(usProviders.free || []),
      ...(usProviders.ads || []),
    ];
    const seen = new Set();
    const providers = allProviders.filter(p => { if(seen.has(p.provider_id)) return false; seen.add(p.provider_id); return true; });

    // Per-platform direct search URLs
    const query = encodeURIComponent(title);
    const PLATFORM_URLS = {
      netflix:   `https://www.netflix.com/search?q=${query}`,
      prime:     `https://www.amazon.com/s?k=${query}&i=instant-video`,
      disney:    `https://www.disneyplus.com/search/${query}`,
      hulu:      `https://www.hulu.com/search?q=${query}`,
      appletv:   `https://tv.apple.com/search?term=${query}`,
      peacock:   `https://www.peacocktv.com/find-something-to-watch?q=${query}`,
      paramount: `https://www.paramountplus.com/search/?query=${query}`,
      max:       `https://www.max.com/search#q=${encodeURIComponent(title)}`,
      tubi:      `https://tubitv.com/search?q=${query}`,
      plex:      `https://app.plex.tv/desktop/#!/search?query=${query}`,
      kanopy:    `https://www.kanopy.com/search?q=${query}`,
      hoopla:    `https://www.hoopladigital.com/search?q=${query}&type=movie`,
    };

    const links = {};
    providers.forEach(p => {
      const platformId = TMDB_PROVIDER_MAP[p.provider_id];
      if (platformId && PLATFORM_URLS[platformId]) {
        links[platformId] = PLATFORM_URLS[platformId];
      }
    });
    return { jwLink, platforms: links };
  } catch(_){
    return { jwLink: `https://www.justwatch.com/us/search?q=${encodeURIComponent(cleanTitle(filmTitle))}`, platforms: {} };
  }
}

// ── STREAMING PLATFORMS ──────────────────────
const PLATFORMS = [
  { id:"netflix",   label:"Netflix",    color:"#E50914", bg:"#141414", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M5.398 0v.006c3.028 8.556 5.37 15.175 8.348 23.596l2.219.578c.197-.556 1.043-3.044 1.855-5.565l-2.494-7.028C12.681 8.396 10.028 1.12 7.38.006z"/><path d="M5.398 0C3.047.01 1.5.01 1.5.01v23.99l3.898.002V0z"/><path d="M14.548 6.154l.055.157c1.134 3.21 2.3 6.495 3.387 9.638l.91 2.603 3.6.94V.012c-2.292 0-3.908.004-3.908.004z"/></svg> },
  { id:"max",       label:"Max",        color:"#0023F5", bg:"#00033d", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M3 3h18v18H3zm2 2v14h14V5zm2 2h2l3 4 3-4h2l-4 5.5L19 17h-2l-3-4-3 4H9l4-4.5z"/></svg> },
  { id:"hulu",      label:"Hulu",       color:"#1CE783", bg:"#101820", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M3 3h7v7H3zm0 11h7v7H3zm11-11h7v7h-7zm0 11h7v7h-7z"/></svg> },
  { id:"prime",     label:"Prime",      color:"#00A8E1", bg:"#0F1111", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14H9V8h2v8zm4 0h-2V8h2v8z"/></svg> },
  { id:"disney",    label:"Disney+",    color:"#113CCF", bg:"#010E27", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M12 2a10 10 0 1 0 0 20A10 10 0 0 0 12 2zm0 2a8 8 0 1 1 0 16A8 8 0 0 1 12 4zm-1 4v4H7v2h4v4h2v-4h4v-2h-4V8z"/></svg> },
  { id:"peacock",   label:"Peacock",    color:"#FA007F", bg:"#0F0F0F", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M12 2l2 7h7l-5.5 4 2 7L12 16l-5.5 4 2-7L3 9h7z"/></svg> },
  { id:"paramount", label:"Paramount+", color:"#0064FF", bg:"#051732", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M12 2L2 19h20L12 2zm0 4l7 11H5l7-11z"/></svg> },
  { id:"appletv",   label:"Apple TV+",  color:"#A2AAAD", bg:"#000000", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701"/></svg> },
  { id:"tubi",      label:"Tubi",       color:"#FA4900", bg:"#0D0D0D", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M4 5h4v14H4zm6 0h4v14h-4zm6 0h4v14h-4z"/></svg> },
  { id:"plex",      label:"Plex",       color:"#E5A00D", bg:"#1C1C1C", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M12 2L2 7v10l10 5 10-5V7L12 2zm0 2.5l7.5 3.75v7.5L12 19.5l-7.5-3.75v-7.5L12 4.5z"/></svg> },
  { id:"kanopy",    label:"Kanopy",     color:"#00A878", bg:"#0a1a16", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M12 3C7 3 3 7 3 12s4 9 9 9 9-4 9-9-4-9-9-9zm0 16a7 7 0 1 1 0-14 7 7 0 0 1 0 14zm-1-7V8h2v4h4v2h-6z"/></svg> },
  { id:"hoopla",    label:"Hoopla",     color:"#FF6B35", bg:"#1a0f0a", icon: <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M12 2a10 10 0 1 0 0 20A10 10 0 0 0 12 2zm0 18a8 8 0 1 1 0-16 8 8 0 0 1 0 16zm-2-5h4v2h-4zm0-8h4v6h-4z"/></svg> },
  { id:"custom",    label:"Other",      color:"#f5c518", bg:"#1a1a1a", icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" width="18" height="18"><circle cx="12" cy="12" r="10"/><path d="M12 8v4m0 4h.01"/></svg> },
];

const FILMS = [
  { t:"Along Came a Spider", e:"🕷️", tags:[["Thriller","thriller"],["Crime","crime"]], s:"Morgan Freeman's detective Alex Cross hunts a kidnapper who snatches a senator's daughter — then starts playing mind games.", wiki:"Along_Came_a_Spider_(film)", yt:"Along Came a Spider 2001 official trailer" },
  { t:"Good Luck Have Fun Don't Die", e:"🎮", tags:[["Action","action"],["Comedy","comedy"]], s:"A darkly comedic thriller set in the cutthroat world of competitive online gaming where the stakes turn very real.", wiki:"Good_Luck,_Have_Fun,_Don't_Die", yt:"Good Luck Have Fun Don't Die 2025 official trailer" },
  { t:"Are You There God? It's Me, Margaret.", e:"💛", tags:[["Drama","drama"],["Comedy","comedy"]], s:"Eleven-year-old Margaret navigates puberty, religion, and fitting in after moving from New York City to the New Jersey suburbs.", wiki:"Are_You_There_God%3F_It%27s_Me%2C_Margaret._(film)", yt:"Are You There God It's Me Margaret 2023 official trailer" },
  { t:"Rental Family", e:"🎭", tags:[["Documentary","doc"]], s:"A Japanese documentary following a for-hire service that provides actors to play family members, friends, and partners for lonely clients.", wiki:"Rental_Family", yt:"Rental Family documentary trailer" },
  { t:"Ready or Not", e:"😈", tags:[["Horror","horror"],["Thriller","thriller"]], s:"A bride's wedding night turns deadly when her new in-laws reveal a murderous family tradition she must survive until dawn.", wiki:"Ready_or_Not_(film)", yt:"Ready or Not 2019 official trailer" },
  { t:"Scream (2022)", e:"🔪", tags:[["Horror","horror"]], tmdbQuery:"Scream 2022", s:"Twenty-five years after the original Woodsboro killings, a new Ghostface returns.", wiki:"Scream_(2022_film)", yt:"Scream 2022 official trailer" },
  { t:"Scream VI (2023)", e:"🔪", tags:[["Horror","horror"]], tmdbQuery:"Scream VI", s:"The survivors escape to New York City, but Ghostface follows.", wiki:"Scream_VI", yt:"Scream VI 2023 official trailer" },
  { t:"Scream VII (2025)", e:"🔪", tags:[["Horror","horror"]], tmdbQuery:"Scream VII", s:"Sidney Prescott makes her long-awaited return as a new wave of murders threatens the Ghostface legacy.", wiki:"Scream_VII", yt:"Scream VII 2025 official trailer" },
  { t:"Boyz n the Hood (1991)", e:"🏙️", tags:[["Drama","drama"],["Crime","crime"]], tmdbQuery:"Boyz n the Hood", s:"Three friends grow up in South Central Los Angeles navigating gang violence and broken dreams.", wiki:"Boyz_n_the_Hood", yt:"Boyz n the Hood 1991 official trailer" },
  { t:"Menace II Society (1993)", e:"🌆", tags:[["Drama","drama"],["Crime","crime"]], tmdbQuery:"Menace II Society", s:"A young man in the Watts projects tries to escape the cycle of street violence.", wiki:"Menace_II_Society", yt:"Menace II Society 1993 official trailer" },
  { t:"Juice (1992)", e:"⚡", tags:[["Drama","drama"],["Crime","crime"]], tmdbQuery:"Juice 1992", s:"Four Harlem teenagers chase respect and power, but when one gets his hands on a gun, everything spirals.", wiki:"Juice_(1992_film)", yt:"Juice 1992 Tupac official trailer" },
  { t:"New Jack City (1991)", e:"💊", tags:[["Crime","crime"],["Action","action"]], tmdbQuery:"New Jack City", s:"A ruthless drug lord builds a crack cocaine empire in 1980s Harlem, and a maverick cop will do anything to bring him down.", wiki:"New_Jack_City", yt:"New Jack City 1991 official trailer" },
  { t:"Friday (1995)", e:"😂", tags:[["Comedy","comedy"],["Drama","drama"]], tmdbQuery:"Friday", s:"A lazy Friday in South Central turns chaotic when Craig owes money to the neighborhood dealer.", wiki:"Friday_(1995_film)", yt:"Friday 1995 Ice Cube official trailer" },
  { t:"Poetic Justice (1993)", e:"✉️", tags:[["Drama","drama"]], tmdbQuery:"Poetic Justice", s:"A grieving young poet road-trips through California with a mailman she can barely stand — and slowly falls for him.", wiki:"Poetic_Justice_(film)", yt:"Poetic Justice 1993 official trailer" },
  { t:"Set It Off (1996)", e:"💰", tags:[["Action","action"],["Crime","crime"]], tmdbQuery:"Set It Off", s:"Four friends pushed to their breaking point turn to bank robbery as their only way out.", wiki:"Set_It_Off_(film)", yt:"Set It Off 1996 official trailer" },
  { t:"Paid in Full (2002)", e:"💎", tags:[["Crime","crime"],["Drama","drama"]], tmdbQuery:"Paid in Full", s:"Based on true events: three Harlem men swept into the crack trade learn the brutal price of fast money.", wiki:"Paid_in_Full_(film)", yt:"Paid in Full 2002 official trailer" },
  { t:"Baby Boy (2001)", e:"👶", tags:[["Drama","drama"]], tmdbQuery:"Baby Boy", s:"A 20-year-old man-child refuses to grow up, juggling two baby mamas while the streets close in.", wiki:"Baby_Boy_(film)", yt:"Baby Boy 2001 John Singleton official trailer" },
  { t:"ATL (2006)", e:"🛼", tags:[["Drama","drama"],["Comedy","comedy"]], tmdbQuery:"ATL 2006", s:"Four Atlanta teens spend their last free summer at the roller rink before life forces them to grow up.", wiki:"ATL_(film)", yt:"ATL 2006 official trailer" },
  { t:"Teenage Mutant Ninja Turtles (1990)", e:"🐢", tags:[["Action","action"],["Comedy","comedy"]], tmdbQuery:"Teenage Mutant Ninja Turtles 1990", s:"Four pizza-obsessed mutant turtles defend New York City from the shadowy Foot Clan and Shredder.", wiki:"Teenage_Mutant_Ninja_Turtles_(1990_film)", yt:"Teenage Mutant Ninja Turtles 1990 official trailer" },
  { t:"Louis Theroux: Inside the Manosphere", e:"📺", tags:[["Documentary","doc"]], s:"Louis Theroux embeds himself with male influencers to understand the online world of misogyny and masculinity.", wiki:"Louis_Theroux:_Inside_the_Manosphere", yt:"Louis Theroux Inside the Manosphere trailer" },
  { t:"Memento", e:"🧩", tags:[["Thriller","thriller"],["Crime","crime"]], s:"A man with no short-term memory uses tattoos and Polaroids to hunt his wife's killer — told in reverse.", wiki:"Memento_(film)", yt:"Memento 2000 Christopher Nolan official trailer" },
  { t:"What's Love Got to Do with It", e:"🎵", tags:[["Drama","drama"]], s:"The unflinching true story of Tina Turner's rise to superstardom and her brutal marriage to Ike Turner.", wiki:"What%27s_Love_Got_to_Do_with_It_(film)", yt:"What's Love Got to Do with It 1993 Tina Turner trailer" },
  { t:"Kiss the Girls", e:"🕵️", tags:[["Thriller","thriller"],["Crime","crime"]], s:"A forensic psychologist races to track a serial kidnapper aided only by the one woman who escaped.", wiki:"Kiss_the_Girls_(film)", yt:"Kiss the Girls 1997 Morgan Freeman official trailer" },
  { t:"High Crimes", e:"⚖️", tags:[["Thriller","thriller"],["Crime","crime"]], s:"A lawyer discovers her husband has been secretly living under a fake identity accused of a wartime massacre.", wiki:"High_Crimes_(film)", yt:"High Crimes 2002 official trailer" },
  { t:"Murder By Numbers", e:"🔍", tags:[["Crime","crime"],["Thriller","thriller"]], s:"Two privileged students engineer what they believe is the perfect murder — but a haunted detective won't let it slide.", wiki:"Murder_by_Numbers_(film)", yt:"Murder by Numbers 2002 Sandra Bullock official trailer" },
  { t:"Taking Lives", e:"🪪", tags:[["Thriller","thriller"],["Crime","crime"]], s:"An FBI profiler hunts a serial killer with a chilling method: he doesn't just kill his victims — he becomes them.", wiki:"Taking_Lives_(film)", yt:"Taking Lives 2004 Angelina Jolie official trailer" },
  { t:"Double Jeopardy", e:"⚖️", tags:[["Thriller","thriller"],["Crime","crime"]], s:"Convicted of killing her husband, a woman discovers he faked his own death. Since she's already been tried, she can't be charged twice.", wiki:"Double_Jeopardy_(1999_film)", yt:"Double Jeopardy 1999 Ashley Judd official trailer" },
  { t:"The Bone Collector", e:"🦴", tags:[["Thriller","thriller"],["Crime","crime"]], s:"A quadriplegic forensic detective guides a rookie cop as a serial killer leaves elaborate clues only he can decode.", wiki:"The_Bone_Collector_(film)", yt:"The Bone Collector 1999 Denzel Washington official trailer" },
  { t:"Copycat", e:"🪞", tags:[["Crime","crime"],["Thriller","thriller"]], s:"An agoraphobic criminal psychologist and a detective hunt a killer who mimics history's most infamous murderers.", wiki:"Copycat_(film)", yt:"Copycat 1995 Sigourney Weaver official trailer" },
  { t:"Primal Fear", e:"😨", tags:[["Crime","crime"],["Thriller","thriller"]], s:"A flashy defense attorney takes the case of a meek altar boy accused of murdering an archbishop — and nothing is what it seems.", wiki:"Primal_Fear_(film)", yt:"Primal Fear 1996 Richard Gere Edward Norton official trailer" },
  { t:"Requiem for a Dream", e:"💉", tags:[["Drama","drama"],["Thriller","thriller"]], s:"Four people's lives spiral as their addictions — to drugs, food, television, and fantasy — consume everything.", wiki:"Requiem_for_a_Dream", yt:"Requiem for a Dream 2000 official trailer" },
  { t:"SLC Punk!", e:"🤘", tags:[["Drama","drama"],["Comedy","comedy"]], s:"A true-blue punk and his best friend navigate identity, rebellion, and the pull of the mainstream in 1980s Salt Lake City.", wiki:"SLC_Punk!", yt:"SLC Punk 1998 official trailer" },
  { t:"The Usual Suspects", e:"🚬", tags:[["Crime","crime"],["Thriller","thriller"]], s:"Five criminals meet in a police lineup and hatch a heist — but who is the mysterious Keyser Söze pulling all the strings?", wiki:"The_Usual_Suspects", yt:"The Usual Suspects 1995 official trailer" },
  { t:"Se7en", e:"🔦", tags:[["Crime","crime"],["Thriller","thriller"]], s:"Two detectives hunt a serial killer who uses the seven deadly sins as his blueprint — leading to a devastating ending.", wiki:"Seven_(1995_film)", yt:"Se7en 1995 Brad Pitt Morgan Freeman official trailer" },
];

const TAG_STYLES = {
  thriller:{ bg:"rgba(200,30,30,0.2)",  color:"#ff8888", border:"rgba(200,30,30,0.3)" },
  horror:  { bg:"rgba(110,20,140,0.2)", color:"#d488ff", border:"rgba(110,20,140,0.3)" },
  comedy:  { bg:"rgba(20,130,70,0.2)",  color:"#6dffaa", border:"rgba(20,130,70,0.3)" },
  drama:   { bg:"rgba(160,100,10,0.2)", color:"#ffcc55", border:"rgba(160,100,10,0.3)" },
  action:  { bg:"rgba(180,90,10,0.2)",  color:"#ffaa55", border:"rgba(180,90,10,0.3)" },
  crime:   { bg:"rgba(60,60,90,0.35)",  color:"#aaaadd", border:"rgba(80,80,130,0.3)" },
  doc:     { bg:"rgba(20,90,170,0.2)",  color:"#77bbff", border:"rgba(20,90,170,0.3)" },
  biopic:  { bg:"rgba(180,40,110,0.2)", color:"#ff88cc", border:"rgba(180,40,110,0.3)" },
};

// ── CONFETTI ─────────────────────────────────
function useConfetti(canvasRef) {
  const particles = useRef([]);
  const animId = useRef(null);
  const COLORS = ['#f5c518','#e63946','#ede0cc','#ff88bb','#6dffaa','#77bbff','#ffaa55','#d488ff'];
  const burst = useCallback((x, y) => {
    const canvas = canvasRef.current; if (!canvas) return;
    for (let i = 0; i < 70; i++) {
      const angle=Math.random()*Math.PI*2, spd=3+Math.random()*8, shape=Math.random();
      particles.current.push({ x, y, vx:Math.cos(angle)*spd, vy:Math.sin(angle)*spd-4,
        color:COLORS[Math.floor(Math.random()*COLORS.length)],
        w:5+Math.random()*7, h:3+Math.random()*5,
        rot:Math.random()*360, rotV:(Math.random()-0.5)*12,
        alpha:1, shape:shape<0.45?'rect':shape<0.75?'circle':'star' });
    }
    cancelAnimationFrame(animId.current); draw();
  }, []);
  function drawStar(ctx,cx,cy,r){ctx.beginPath();for(let i=0;i<5;i++){const a=(i*4*Math.PI)/5-Math.PI/2,b=a+Math.PI/5;if(i===0)ctx.moveTo(cx+r*Math.cos(a),cy+r*Math.sin(a));else ctx.lineTo(cx+r*Math.cos(a),cy+r*Math.sin(a));ctx.lineTo(cx+(r*0.45)*Math.cos(b),cy+(r*0.45)*Math.sin(b));}ctx.closePath();}
  function draw(){
    const canvas=canvasRef.current; if(!canvas) return;
    const ctx=canvas.getContext('2d');
    ctx.clearRect(0,0,canvas.width,canvas.height);
    particles.current=particles.current.filter(p=>p.alpha>0.01);
    particles.current.forEach(p=>{
      p.x+=p.vx;p.y+=p.vy;p.vy+=0.3;p.vx*=0.99;p.alpha-=0.016;p.rot+=p.rotV;
      ctx.save();ctx.globalAlpha=Math.max(0,p.alpha);ctx.fillStyle=p.color;ctx.translate(p.x,p.y);ctx.rotate(p.rot*Math.PI/180);
      if(p.shape==='rect')ctx.fillRect(-p.w/2,-p.h/2,p.w,p.h);
      else if(p.shape==='circle'){ctx.beginPath();ctx.arc(0,0,p.w/2,0,Math.PI*2);ctx.fill();}
      else{drawStar(ctx,0,0,p.w/2);ctx.fill();}
      ctx.restore();
    });
    if(particles.current.length>0)animId.current=requestAnimationFrame(draw);
    else ctx.clearRect(0,0,canvas.width,canvas.height);
  }
  return { burst };
}

// ── HERO BANNER ───────────────────────────────
function HeroBanner({ films, watched, onOpenFilm }) {
  const [heroIndex, setHeroIndex] = useState(0);
  const [backdropSrc, setBackdropSrc] = useState(null);
  const [posterSrc, setPosterSrc] = useState(null);
  const [youtubeKey, setYoutubeKey] = useState(null);
  const [showTrailer, setShowTrailer] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [transitioning, setTransitioning] = useState(false);
  const autoTimer = useRef(null);

  // Pick unwatched films for hero rotation, fallback to all
  const heroFilms = films.filter(f => !watched[f.t]).slice(0, 8);
  const film = heroFilms[heroIndex % heroFilms.length];

  useEffect(() => {
    if (!film) return;
    setLoaded(false);
    setShowTrailer(false);
    setBackdropSrc(null);
    setPosterSrc(null);
    setYoutubeKey(null);
    fetchTMDBBackdrop(film).then(data => {
      if (data?.backdrop) setBackdropSrc(data.backdrop);
      if (data?.poster) setPosterSrc(data.poster);
      if (data?.youtubeKey) setYoutubeKey(data.youtubeKey);
    });
  }, [heroIndex, film?.t]);

  // Auto-advance every 12 seconds
  useEffect(() => {
    if (showTrailer) return;
    autoTimer.current = setTimeout(() => advance(), 12000);
    return () => clearTimeout(autoTimer.current);
  }, [heroIndex, showTrailer]);

  function advance() {
    if (!heroFilms.length) return;
    setTransitioning(true);
    setTimeout(() => {
      setHeroIndex(i => (i + 1) % heroFilms.length);
      setTransitioning(false);
    }, 400);
  }

  function goTo(i) {
    clearTimeout(autoTimer.current);
    setTransitioning(true);
    setTimeout(() => { setHeroIndex(i); setTransitioning(false); }, 400);
  }

  if (!film) return null;

  const ytEmbedId = null; // We open YouTube directly vs embedding to avoid autoplay restrictions

  return (
    <div style={{ position:"relative", width:"100%", height:"clamp(420px, 56vw, 680px)", overflow:"hidden", marginBottom:0 }}>

      {/* Backdrop */}
      <div style={{ position:"absolute", inset:0, background:"#0a0a0d", transition:"opacity 0.6s", opacity: transitioning ? 0 : 1 }}>
        {backdropSrc && (
          <img src={backdropSrc} alt="" onLoad={()=>setLoaded(true)}
            style={{ width:"100%", height:"100%", objectFit:"cover", opacity: loaded ? 1 : 0, transition:"opacity 0.8s", display:"block" }} />
        )}
        {/* Gradient overlays */}
        <div style={{ position:"absolute", inset:0, background:"linear-gradient(to right, rgba(10,10,13,0.95) 0%, rgba(10,10,13,0.6) 50%, rgba(10,10,13,0.15) 100%)" }} />
        <div style={{ position:"absolute", inset:0, background:"linear-gradient(to top, rgba(10,10,13,1) 0%, transparent 40%)" }} />
        <div style={{ position:"absolute", inset:0, background:"linear-gradient(to bottom, rgba(10,10,13,0.5) 0%, transparent 20%)" }} />
      </div>

      {/* Trailer iframe overlay */}
      {showTrailer && (
        <div style={{ position:"absolute", inset:0, zIndex:20, background:"#000", display:"flex", alignItems:"center", justifyContent:"center" }}>
          {youtubeKey ? (
            <iframe
              src={`https://www.youtube.com/embed/${youtubeKey}?autoplay=1&rel=0`}
              style={{ width:"100%", height:"100%", border:"none" }}
              allow="autoplay; fullscreen"
              allowFullScreen />
          ) : (
            // Fallback: open YouTube search in new tab
            <div style={{ display:"flex", flexDirection:"column", alignItems:"center", gap:16 }}>
              <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.8rem", color:"#ede0cc" }}>No embedded trailer found</div>
              <a href={`https://www.youtube.com/results?search_query=${encodeURIComponent((film.yt||film.t)+" official trailer")}`}
                target="_blank" rel="noopener"
                style={{ fontFamily:"'Courier New',monospace", fontSize:"0.75rem", color:"#f5c518", border:"1px solid #f5c518", padding:"10px 20px", borderRadius:4, textDecoration:"none" }}>
                Search on YouTube ↗
              </a>
            </div>
          )}
          <button onClick={()=>setShowTrailer(false)}
            style={{ position:"absolute", top:86, right:16, background:"rgba(0,0,0,0.7)", border:"1px solid rgba(255,255,255,0.2)", color:"#fff", borderRadius:"50%", width:40, height:40, fontSize:"1.1rem", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center", zIndex:21 }}>✕</button>
        </div>
      )}

      {/* Content */}
      {!showTrailer && (
        <div style={{ position:"absolute", inset:0, display:"flex", alignItems:"center", padding:"0 5% 60px", transition:"opacity 0.4s", opacity: transitioning ? 0 : 1 }}>
          <div style={{ display:"flex", gap:40, alignItems:"center", maxWidth:900 }}>

            {/* Poster */}
            <div onClick={()=>setShowTrailer(true)}
              style={{ width:"clamp(120px,14vw,200px)", flexShrink:0, aspectRatio:"2/3", borderRadius:8, overflow:"hidden", background:"#111", boxShadow:"0 24px 60px rgba(0,0,0,0.8), 0 0 0 1px rgba(255,255,255,0.08)", cursor:"pointer", position:"relative", transition:"transform 0.2s, box-shadow 0.2s", flexShrink:0 }}
              onMouseEnter={e=>{ e.currentTarget.style.transform="scale(1.04)"; e.currentTarget.style.boxShadow="0 32px 80px rgba(0,0,0,0.9), 0 0 0 2px rgba(245,197,24,0.4)"; }}
              onMouseLeave={e=>{ e.currentTarget.style.transform="scale(1)"; e.currentTarget.style.boxShadow="0 24px 60px rgba(0,0,0,0.8), 0 0 0 1px rgba(255,255,255,0.08)"; }}>
              {posterSrc && <img src={posterSrc} alt={film.t} style={{ width:"100%", height:"100%", objectFit:"cover", display:"block" }} />}
              {/* Play overlay */}
              <div style={{ position:"absolute", inset:0, background:"rgba(0,0,0,0.3)", display:"flex", alignItems:"center", justifyContent:"center", opacity:0, transition:"opacity 0.2s" }}
                onMouseEnter={e=>e.currentTarget.style.opacity=1} onMouseLeave={e=>e.currentTarget.style.opacity=0}>
                <div style={{ width:56, height:56, borderRadius:"50%", background:"rgba(245,197,24,0.9)", display:"flex", alignItems:"center", justifyContent:"center", boxShadow:"0 0 24px rgba(245,197,24,0.5)" }}>
                  <span style={{ fontSize:"1.4rem", marginLeft:4 }}>▶</span>
                </div>
              </div>
            </div>

            {/* Info */}
            <div style={{ flex:1, minWidth:0 }}>
              {/* Tags */}
              <div style={{ display:"flex", gap:6, marginBottom:12, flexWrap:"wrap" }}>
                {film.tags?.slice(0,3).map(([label,key])=>{ const s=TAG_STYLES[key]||TAG_STYLES.crime; return(
                  <span key={label} style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", letterSpacing:"0.08em", padding:"3px 8px", borderRadius:3, textTransform:"uppercase", fontWeight:"bold", background:s.bg, color:s.color, border:`1px solid ${s.border}` }}>{label}</span>
                );})}
              </div>

              {/* Title */}
              <h2 style={{ fontFamily:"'Impact','Arial Black',sans-serif", fontSize:"clamp(1.8rem,4vw,3.5rem)", fontWeight:900, color:"#ede0cc", lineHeight:0.95, textTransform:"uppercase", letterSpacing:"-0.01em", marginBottom:16, textShadow:"0 2px 20px rgba(0,0,0,0.8)" }}>
                {film.t}
              </h2>

              {/* Summary */}
              {film.s && (
                <p style={{ fontFamily:"'Georgia',serif", fontSize:"clamp(0.75rem,1.2vw,0.9rem)", color:"rgba(237,224,204,0.8)", lineHeight:1.6, marginBottom:24, maxWidth:480, fontStyle:"italic" }}>
                  {film.s}
                </p>
              )}

              {/* Buttons */}
              <div style={{ display:"flex", gap:12, flexWrap:"wrap" }}>
                <button onClick={()=>setShowTrailer(true)}
                  style={{ display:"flex", alignItems:"center", gap:8, fontFamily:"'Courier New',monospace", fontSize:"0.75rem", letterSpacing:"0.15em", textTransform:"uppercase", fontWeight:"bold", padding:"12px 28px", borderRadius:4, border:"none", background:"#f5c518", color:"#0a0a0d", cursor:"pointer", transition:"all 0.18s" }}
                  onMouseEnter={e=>{ e.currentTarget.style.background="#fff"; e.currentTarget.style.transform="translateY(-1px)"; }}
                  onMouseLeave={e=>{ e.currentTarget.style.background="#f5c518"; e.currentTarget.style.transform="none"; }}>
                  ▶ &nbsp;Play Trailer
                </button>
                <button onClick={()=>onOpenFilm(film)}
                  style={{ display:"flex", alignItems:"center", gap:8, fontFamily:"'Courier New',monospace", fontSize:"0.75rem", letterSpacing:"0.15em", textTransform:"uppercase", fontWeight:"bold", padding:"12px 28px", borderRadius:4, border:"1px solid rgba(255,255,255,0.3)", background:"rgba(255,255,255,0.1)", color:"#ede0cc", cursor:"pointer", transition:"all 0.18s", backdropFilter:"blur(4px)" }}
                  onMouseEnter={e=>{ e.currentTarget.style.background="rgba(255,255,255,0.2)"; e.currentTarget.style.transform="translateY(-1px)"; }}
                  onMouseLeave={e=>{ e.currentTarget.style.background="rgba(255,255,255,0.1)"; e.currentTarget.style.transform="none"; }}>
                  ℹ &nbsp;More Info
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Bottom nav dots + arrows */}
      {!showTrailer && heroFilms.length > 1 && (
        <div style={{ position:"absolute", bottom:24, left:"5%", display:"flex", alignItems:"center", gap:12, zIndex:10 }}>
          <button onClick={()=>goTo((heroIndex-1+heroFilms.length)%heroFilms.length)}
            style={{ background:"rgba(255,255,255,0.1)", border:"1px solid rgba(255,255,255,0.2)", color:"#ede0cc", borderRadius:"50%", width:32, height:32, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center", fontSize:"0.8rem", backdropFilter:"blur(4px)", transition:"all 0.15s" }}
            onMouseEnter={e=>e.currentTarget.style.background="rgba(255,255,255,0.25)"} onMouseLeave={e=>e.currentTarget.style.background="rgba(255,255,255,0.1)"}>‹</button>
          <div style={{ display:"flex", gap:6 }}>
            {heroFilms.map((_, i) => (
              <button key={i} onClick={()=>goTo(i)}
                style={{ width: i===heroIndex ? 20 : 6, height:6, borderRadius:3, border:"none", background: i===heroIndex ? "#f5c518" : "rgba(255,255,255,0.3)", cursor:"pointer", transition:"all 0.3s", padding:0 }} />
            ))}
          </div>
          <button onClick={()=>goTo((heroIndex+1)%heroFilms.length)}
            style={{ background:"rgba(255,255,255,0.1)", border:"1px solid rgba(255,255,255,0.2)", color:"#ede0cc", borderRadius:"50%", width:32, height:32, cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center", fontSize:"0.8rem", backdropFilter:"blur(4px)", transition:"all 0.15s" }}
            onMouseEnter={e=>e.currentTarget.style.background="rgba(255,255,255,0.25)"} onMouseLeave={e=>e.currentTarget.style.background="rgba(255,255,255,0.1)"}>›</button>
        </div>
      )}

      {/* Bottom fade into page */}
      <div style={{ position:"absolute", bottom:0, left:0, right:0, height:80, background:"linear-gradient(to bottom, transparent, #0a0a0d)", pointerEvents:"none" }} />
    </div>
  );
}

// ── AUTH MODAL ───────────────────────────────
function AuthModal() {
  const [email,setEmail]=useState(""); const [displayName,setDisplayName]=useState("");
  const [mode,setMode]=useState("signup"); const [status,setStatus]=useState(null); const [loading,setLoading]=useState(false);
  async function handleSignup(){
    if(!displayName.trim()){setStatus("Enter a display name.");return;}
    setLoading(true);setStatus(null);
    const {data,error}=await supabase.auth.signUp({email,password:displayName+"_watchqueue_2024",options:{data:{display_name:displayName}}});
    if(error){setStatus(error.message);setLoading(false);return;}
    if(data?.user) await supabase.from("profiles").upsert({id:data.user.id,display_name:displayName},{onConflict:"id"});
    setStatus("Account created! Logging you in...");setLoading(false);
  }
  async function handleLogin(){
    setLoading(true);setStatus(null);
    const {error}=await supabase.auth.signInWithPassword({email,password:displayName+"_watchqueue_2024"});
    if(error)setStatus(error.message); setLoading(false);
  }
  const isSignup=mode==="signup";
  return(
    <div style={{position:"fixed",inset:0,background:"#0a0a0d",display:"flex",alignItems:"center",justifyContent:"center",zIndex:99999}}>
      <div style={{position:"absolute",inset:0,opacity:0.04,backgroundImage:`url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='300'%3E%3Cfilter id='g'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='300' height='300' filter='url(%23g)'/%3E%3C/svg%3E")`,pointerEvents:"none"}} />
      <div style={{width:"100%",maxWidth:360,padding:"0 24px"}}>
        <div style={{textAlign:"center",marginBottom:36}}>
          <div style={{fontFamily:"'Impact','Arial Black',sans-serif",fontSize:"3.5rem",color:"#f5c518",textShadow:"2px 2px 0 #7a620a",lineHeight:1,marginBottom:8}}>🎬</div>
          <div style={{fontFamily:"'Impact','Arial Black',sans-serif",fontSize:"2rem",color:"#f5c518",textShadow:"2px 2px 0 #7a620a",letterSpacing:"-0.01em",textTransform:"uppercase"}}>The Watch Queue</div>
          <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.6rem",color:"#4a4a5e",letterSpacing:"0.3em",textTransform:"uppercase",marginTop:8}}>// your crew's movie tracker //</div>
        </div>
        <div style={{display:"flex",marginBottom:20,border:"1px solid rgba(255,255,255,0.08)",borderRadius:5,overflow:"hidden"}}>
          {[{k:"signup",l:"Sign Up"},{k:"login",l:"Log In"}].map(m=>(
            <button key={m.k} onClick={()=>{setMode(m.k);setStatus(null);}} style={{flex:1,fontFamily:"'Courier New',monospace",fontSize:"0.65rem",letterSpacing:"0.15em",textTransform:"uppercase",padding:"10px",border:"none",background:mode===m.k?"rgba(245,197,24,0.12)":"transparent",color:mode===m.k?"#f5c518":"#4a4a5e",cursor:"pointer",borderRight:m.k==="signup"?"1px solid rgba(255,255,255,0.08)":"none",transition:"all 0.15s"}}>{m.l}</button>
          ))}
        </div>
        <div style={{display:"flex",flexDirection:"column",gap:10}}>
          <input value={email} onChange={e=>setEmail(e.target.value)} placeholder="email address" type="email" onKeyDown={e=>e.key==="Enter"&&(isSignup?handleSignup():handleLogin())} style={{background:"rgba(255,255,255,0.04)",border:"1px solid rgba(255,255,255,0.1)",borderRadius:4,padding:"12px 14px",color:"#ede0cc",fontFamily:"'Courier New',monospace",fontSize:"0.8rem",outline:"none",width:"100%",boxSizing:"border-box"}} />
          <input value={displayName} onChange={e=>setDisplayName(e.target.value)} placeholder={isSignup?"display name (e.g. Brittany)":"your display name"} onKeyDown={e=>e.key==="Enter"&&(isSignup?handleSignup():handleLogin())} style={{background:"rgba(255,255,255,0.04)",border:"1px solid rgba(255,255,255,0.1)",borderRadius:4,padding:"12px 14px",color:"#ede0cc",fontFamily:"'Courier New',monospace",fontSize:"0.8rem",outline:"none",width:"100%",boxSizing:"border-box"}} />
        </div>
        <button onClick={isSignup?handleSignup:handleLogin} disabled={loading} style={{width:"100%",marginTop:14,background:"#f5c518",border:"none",borderRadius:4,padding:"13px",fontFamily:"'Courier New',monospace",fontSize:"0.72rem",fontWeight:"bold",letterSpacing:"0.18em",textTransform:"uppercase",color:"#0a0a0d",cursor:"pointer",opacity:loading?0.6:1}}>
          {loading?"...":(isSignup?"Create Account":"Enter the Queue")}
        </button>
        {status&&<div style={{marginTop:14,fontFamily:"'Courier New',monospace",fontSize:"0.65rem",color:status.includes("created")||status.includes("sent")?"#6dffaa":"#ff8888",textAlign:"center",lineHeight:1.5}}>{status}</div>}
      </div>
    </div>
  );
}

// ── CONFIRM REMOVE MODAL ──────────────────────
function ConfirmRemoveModal({ film, onConfirm, onCancel }) {
  useEffect(()=>{ const h=e=>{ if(e.key==="Escape") onCancel(); }; window.addEventListener("keydown",h); return()=>window.removeEventListener("keydown",h); },[onCancel]);
  return(
    <div onClick={onCancel} style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.88)",zIndex:20000,display:"flex",alignItems:"center",justifyContent:"center",padding:20,backdropFilter:"blur(10px)"}}>
      <div onClick={e=>e.stopPropagation()} style={{background:"#111116",border:"1px solid rgba(230,57,70,0.3)",borderRadius:10,width:"100%",maxWidth:360,padding:"32px 28px",animation:"modalIn 0.2s cubic-bezier(0.34,1.56,0.64,1)"}}>
        <div style={{textAlign:"center",marginBottom:20}}>
          <div style={{fontSize:"2rem",marginBottom:12}}>🗑️</div>
          <div style={{fontFamily:"'Impact','Arial Black',sans-serif",fontSize:"1.1rem",color:"#ede0cc",marginBottom:10}}>Remove from Queue?</div>
          <div style={{fontFamily:"'Georgia',serif",fontSize:"0.78rem",color:"#6e6e88",fontStyle:"italic",lineHeight:1.5}}>"{film.t}" will be removed from your list.</div>
        </div>
        <div style={{display:"flex",gap:10}}>
          <button onClick={onCancel} style={{flex:1,fontFamily:"'Courier New',monospace",fontSize:"0.68rem",letterSpacing:"0.15em",textTransform:"uppercase",padding:"11px",borderRadius:4,cursor:"pointer",border:"1px solid rgba(255,255,255,0.1)",background:"transparent",color:"#6e6e88"}} onMouseEnter={e=>{e.currentTarget.style.borderColor="rgba(255,255,255,0.25)";e.currentTarget.style.color="#ede0cc";}} onMouseLeave={e=>{e.currentTarget.style.borderColor="rgba(255,255,255,0.1)";e.currentTarget.style.color="#6e6e88";}}>Cancel</button>
          <button onClick={onConfirm} style={{flex:1,fontFamily:"'Courier New',monospace",fontSize:"0.68rem",letterSpacing:"0.15em",textTransform:"uppercase",padding:"11px",borderRadius:4,cursor:"pointer",border:"none",background:"rgba(230,57,70,0.85)",color:"#fff",fontWeight:"bold"}} onMouseEnter={e=>e.currentTarget.style.background="#e63946"} onMouseLeave={e=>e.currentTarget.style.background="rgba(230,57,70,0.85)"}>Remove</button>
        </div>
      </div>
    </div>
  );
}

// ── STREAMING ICONS (on tile hover) ──────────
function StreamingBadges({ links }) {
  if (!links || !Object.keys(links).filter(k=>links[k]).length) return null;
  const active = PLATFORMS.filter(p => links[p.id]);
  return (
    <div style={{display:"flex",gap:3,flexWrap:"wrap"}}>
      {active.map(p=>(
        <a key={p.id} href={links[p.id]} target="_blank" rel="noopener"
          onClick={e=>e.stopPropagation()}
          title={`Watch on ${p.label}`}
          style={{width:22,height:22,borderRadius:4,background:p.bg,border:`1px solid ${p.color}44`,display:"flex",alignItems:"center",justifyContent:"center",color:p.color,textDecoration:"none",flexShrink:0,transition:"transform 0.15s,box-shadow 0.15s"}}
          onMouseEnter={e=>{e.currentTarget.style.transform="scale(1.2)";e.currentTarget.style.boxShadow=`0 0 8px ${p.color}66`;}}
          onMouseLeave={e=>{e.currentTarget.style.transform="scale(1)";e.currentTarget.style.boxShadow="none";}}>
          {p.icon}
        </a>
      ))}
    </div>
  );
}

// ── POSTER TILE ───────────────────────────────
function PosterTile({ film, isWatched, friendsWatched, rating, streamingLinks, onOpen, onRemove, index, isDragging, dragHandlers }) {
  const [posterSrc,setPosterSrc]=useState(film.posterUrl||null);
  const [posterLoaded,setPosterLoaded]=useState(false);
  const [hovered,setHovered]=useState(false);
  const [trashHovered,setTrashHovered]=useState(false);
  const [confirmOpen,setConfirmOpen]=useState(false);
  const [visible,setVisible]=useState(false);

  useEffect(()=>{ const t=setTimeout(()=>setVisible(true),index*30); return()=>clearTimeout(t); },[index]);
  useEffect(()=>{
    if(film.posterUrl){ setPosterSrc(film.posterUrl); return; }
    fetchTMDBPoster(film,"w300").then(src=>{ if(src) setPosterSrc(src); });
  },[film.t,film.posterUrl]);

  const hasStreaming = streamingLinks && Object.values(streamingLinks).some(Boolean);

  return(
    <>
    {confirmOpen&&<ConfirmRemoveModal film={film} onConfirm={()=>{setConfirmOpen(false);onRemove(film);}} onCancel={()=>setConfirmOpen(false)} />}
    <div
      {...dragHandlers}
      onClick={()=>onOpen(film)}
      onMouseEnter={()=>setHovered(true)} onMouseLeave={()=>setHovered(false)}
      style={{
        position:"relative",borderRadius:6,overflow:"hidden",
        aspectRatio:"2/3",background:"#0d0d18",
        border:`2px solid ${isDragging?"rgba(245,197,24,0.8)":isWatched?"rgba(245,197,24,0.45)":hovered?"rgba(245,197,24,0.55)":"rgba(255,255,255,0.06)"}`,
        opacity: isDragging ? 0.5 : visible ? 1 : 0,
        transform: isDragging ? "scale(1.05) rotate(2deg)" : visible ? "translateY(0) scale(1)" : "translateY(14px) scale(0.96)",
        transition:`opacity 0.38s ease ${index*0.025}s, transform 0.38s ease ${index*0.025}s, border-color 0.2s, box-shadow 0.2s`,
        boxShadow: isDragging ? "0 20px 60px rgba(0,0,0,0.9)" : hovered?"0 16px 48px rgba(0,0,0,0.75)":"0 4px 16px rgba(0,0,0,0.5)",
        cursor: isDragging ? "grabbing" : "grab",
        userSelect:"none",
      }}>

      {/* Placeholder */}
      <div style={{position:"absolute",inset:0,display:"flex",alignItems:"center",justifyContent:"center",flexDirection:"column",gap:6,zIndex:0}}>
        <span style={{fontSize:"2rem",opacity:0.15}}>🎬</span>
        <span style={{fontFamily:"'Courier New',monospace",fontSize:"0.45rem",color:"rgba(255,255,255,0.12)",textAlign:"center",padding:"0 8px",letterSpacing:"0.05em",lineHeight:1.4}}>{film.t}</span>
      </div>

      {/* Poster */}
      {posterSrc&&(
        <img src={posterSrc} alt={film.t} onLoad={()=>setPosterLoaded(true)}
          style={{position:"absolute",inset:0,width:"100%",height:"100%",objectFit:"cover",
            opacity:posterLoaded?1:0,transition:"opacity 0.5s, filter 0.4s, transform 0.4s",zIndex:1,
            filter:isWatched?"grayscale(60%) brightness(0.6)":"none",
            transform:hovered&&!isWatched?"scale(1.04)":"scale(1)",
            pointerEvents:"none"}} />
      )}

      {/* Watched overlay */}
      {isWatched&&(
        <div style={{position:"absolute",inset:0,background:"rgba(10,10,13,0.6)",display:"flex",alignItems:"center",justifyContent:"center",zIndex:3,pointerEvents:"none"}}>
          <div style={{width:46,height:46,borderRadius:"50%",background:"#f5c518",display:"flex",alignItems:"center",justifyContent:"center",boxShadow:"0 0 0 5px rgba(245,197,24,0.18),0 0 28px rgba(245,197,24,0.35)"}}>
            <span style={{fontSize:"1.4rem",lineHeight:1,color:"#0a0a0d"}}>✓</span>
          </div>
        </div>
      )}

      {/* Hover overlay */}
      {!isWatched&&(
        <div style={{position:"absolute",inset:0,background:"linear-gradient(to top,rgba(0,0,0,0.96) 0%,rgba(0,0,0,0.3) 55%,transparent 100%)",opacity:hovered?1:0,transition:"opacity 0.22s",zIndex:2,display:"flex",flexDirection:"column",justifyContent:"flex-end",padding:"10px 9px 9px",pointerEvents:"none"}}>
          <div style={{fontFamily:"'Georgia',serif",fontSize:"0.72rem",fontWeight:"bold",color:"#ede0cc",lineHeight:1.3,marginBottom:5}}>{film.t}</div>
          <div style={{display:"flex",flexWrap:"wrap",gap:3,marginBottom:hasStreaming?6:0}}>
            {film.tags?.slice(0,2).map(([label,key])=>{ const s=TAG_STYLES[key]||TAG_STYLES.crime; return(
              <span key={label} style={{fontFamily:"'Courier New',monospace",fontSize:"0.48rem",letterSpacing:"0.06em",padding:"1px 5px",borderRadius:2,textTransform:"uppercase",fontWeight:"bold",background:s.bg,color:s.color,border:`1px solid ${s.border}`}}>{label}</span>
            );})}
          </div>
          {hasStreaming && <div style={{pointerEvents:"all"}}><StreamingBadges links={streamingLinks} /></div>}
        </div>
      )}

      {/* Watched bottom strip */}
      {isWatched&&(
        <div style={{position:"absolute",bottom:0,left:0,right:0,padding:"8px 9px 7px",zIndex:4,background:"linear-gradient(to top,rgba(0,0,0,0.85),transparent)",pointerEvents:"none"}}>
          <div style={{fontFamily:"'Georgia',serif",fontSize:"0.62rem",color:"rgba(245,197,24,0.75)",lineHeight:1.3,fontStyle:"italic"}}>{film.t}</div>
          {rating>0&&<div style={{color:"#f5c518",fontSize:"0.55rem",marginTop:2,letterSpacing:2}}>{"★".repeat(rating)}{"☆".repeat(5-rating)}</div>}
          {hasStreaming&&<div style={{marginTop:5,pointerEvents:"all"}}><StreamingBadges links={streamingLinks} /></div>}
        </div>
      )}

      {/* Friends badge */}
      {friendsWatched?.length>0&&(
        <div style={{position:"absolute",top:6,left:6,zIndex:5,background:"rgba(109,255,170,0.18)",border:"1px solid rgba(109,255,170,0.4)",borderRadius:10,padding:"2px 7px",fontFamily:"'Courier New',monospace",fontSize:"0.5rem",color:"#6dffaa",pointerEvents:"none"}}>
          👥 {friendsWatched.length}
        </div>
      )}

      {/* Drag indicator */}
      <div style={{position:"absolute",top:6,right:32,zIndex:5,opacity:hovered?0.4:0,transition:"opacity 0.2s",color:"rgba(255,255,255,0.8)",fontSize:"0.85rem",pointerEvents:"none",lineHeight:1}}>⠿</div>

      {/* Trash icon */}
      <button onClick={e=>{ e.stopPropagation(); setConfirmOpen(true); }}
        onMouseEnter={e=>{ e.stopPropagation(); setTrashHovered(true); }} onMouseLeave={()=>setTrashHovered(false)}
        style={{position:"absolute",top:6,right:6,zIndex:6,width:26,height:26,borderRadius:"50%",
          background:trashHovered?"rgba(230,57,70,0.9)":"rgba(10,10,13,0.7)",
          border:`1px solid ${trashHovered?"rgba(230,57,70,0.8)":"rgba(255,255,255,0.15)"}`,
          color:trashHovered?"#fff":"rgba(255,255,255,0.45)",fontSize:"0.65rem",cursor:"pointer",
          display:"flex",alignItems:"center",justifyContent:"center",
          opacity:hovered||trashHovered?1:0,transition:"all 0.18s",backdropFilter:"blur(4px)"}}>🗑</button>
    </div>
    </>
  );
}

// ── FILM MODAL ────────────────────────────────
function FilmModal({ film, isWatched, note, rating, streamingLinks, friendsWatched, friendsRatings, onToggle, onNoteChange, onRatingChange, onStreamingChange, onDelete, onClose, isCustom, currentUser, darkMode, watchTogether, onWatchTogetherChange, sharedCustomUrl, onSharedCustomUrlChange }) {
  const [localNote,setLocalNote]=useState(note||"");
  const [posterSrc,setPosterSrc]=useState(film.posterUrl||null);
  const [posterLoaded,setPosterLoaded]=useState(false);
  const [autoProviders,setAutoProviders]=useState({});
  const [jwLink,setJwLink]=useState(null);
  const [providersLoading,setProvidersLoading]=useState(true);

  useEffect(()=>{
    if(film.posterUrl){setPosterSrc(film.posterUrl);return;}
    fetchTMDBPoster(film,"w500").then(src=>{ if(src) setPosterSrc(src); });
  },[film.t,film.posterUrl]);

  // Auto-fetch streaming availability from TMDB
  useEffect(()=>{
    setProvidersLoading(true);
    fetchWatchProviders(film.t).then(result=>{
      setAutoProviders(result?.platforms||{});
      setJwLink(result?.jwLink||`https://www.justwatch.com/us/search?q=${encodeURIComponent(cleanTitle(film.t))}`);
      setProvidersLoading(false);
    });
  },[film.t]);

  useEffect(()=>{
    const h=e=>{ if(e.key==="Escape") onClose(); };
    window.addEventListener("keydown",h); return()=>window.removeEventListener("keydown",h);
  },[onClose]);

  const ytUrl=`https://www.youtube.com/results?search_query=${encodeURIComponent(film.yt||film.t+" trailer")}`;
  // Platform buttons always use fresh autoProviders (direct links), only custom key uses saved value
  const mergedLinks = { ...autoProviders, ...(streamingLinks?.custom ? { custom: streamingLinks.custom } : {}) };
  const linksWithTitle = { ...mergedLinks, _title: film.t };

  return(
    <div onClick={onClose} style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.88)",zIndex:10000,display:"flex",alignItems:"center",justifyContent:"center",padding:20,backdropFilter:"blur(10px)"}}>
      <div onClick={e=>e.stopPropagation()} style={{background:"#111116",border:"1px solid rgba(245,197,24,0.2)",borderRadius:10,width:"100%",maxWidth:540,maxHeight:"90vh",overflowY:"auto",position:"relative",animation:"modalIn 0.25s cubic-bezier(0.34,1.56,0.64,1)"}}>
        <button onClick={onClose} style={{position:"absolute",top:14,right:14,background:"none",border:"none",color:"#4a4a5e",fontSize:"1.2rem",cursor:"pointer",zIndex:1,lineHeight:1,padding:4}} onMouseEnter={e=>e.target.style.color="#ede0cc"} onMouseLeave={e=>e.target.style.color="#4a4a5e"}>✕</button>

        <div style={{display:"flex",gap:0}}>
          <div style={{width:150,flexShrink:0,background:"#0d0d18",borderRadius:"10px 0 0 0",overflow:"hidden",position:"relative",display:"flex",alignItems:"center",justifyContent:"center",minHeight:220}}>
            <span style={{fontSize:"2rem",opacity:0.12,position:"absolute"}}>🎬</span>
            {posterSrc&&<img src={posterSrc} alt={film.t} onLoad={()=>setPosterLoaded(true)} style={{position:"absolute",inset:0,width:"100%",height:"100%",objectFit:"cover",opacity:posterLoaded?1:0,transition:"opacity 0.5s",filter:isWatched?"grayscale(40%)":"none"}} />}
            {isWatched&&(<div style={{position:"absolute",inset:0,background:"rgba(10,10,13,0.55)",display:"flex",alignItems:"center",justifyContent:"center",zIndex:2}}><div style={{width:40,height:40,borderRadius:"50%",background:"#f5c518",display:"flex",alignItems:"center",justifyContent:"center",boxShadow:"0 0 20px rgba(245,197,24,0.5)"}}><span style={{fontSize:"1.2rem",color:"#0a0a0d"}}>✓</span></div></div>)}
          </div>
          <div style={{flex:1,padding:"22px 20px 18px",minWidth:0}}>
            <div style={{fontFamily:"'Georgia',serif",fontSize:"1rem",fontWeight:"bold",color:isWatched?"#6e6e88":"#ede0cc",lineHeight:1.3,marginBottom:10,paddingRight:28}}>{film.e} {film.t}</div>
            <div style={{display:"flex",flexWrap:"wrap",gap:4,marginBottom:12}}>
              {film.tags?.map(([label,key])=>{ const s=TAG_STYLES[key]||TAG_STYLES.crime; return(<span key={label} style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.07em",padding:"2px 7px",borderRadius:2,textTransform:"uppercase",fontWeight:"bold",background:s.bg,color:s.color,border:`1px solid ${s.border}`}}>{label}</span>);})}
            </div>
            {film.s&&<p style={{fontFamily:"'Georgia',serif",fontSize:"0.76rem",color:"#6e6e88",fontStyle:"italic",lineHeight:1.6,marginBottom:14}}>{film.s}</p>}
            {friendsWatched?.length>0&&(<div style={{fontFamily:"'Courier New',monospace",fontSize:"0.6rem",color:"#6dffaa",marginBottom:12,opacity:0.85}}>👥 {friendsWatched.join(", ")} watched this</div>)}
            <div style={{display:"flex",gap:8,alignItems:"center",flexWrap:"wrap"}}>
              <a href={ytUrl} target="_blank" rel="noopener"
                style={{display:"inline-flex",alignItems:"center",gap:5,fontFamily:"'Courier New',monospace",fontSize:"0.6rem",letterSpacing:"0.1em",textTransform:"uppercase",color:"#e63946",textDecoration:"none",border:"1px solid rgba(230,57,70,0.35)",padding:"5px 12px",borderRadius:3,transition:"all 0.15s"}}
                onMouseEnter={e=>e.currentTarget.style.background="rgba(230,57,70,0.15)"} onMouseLeave={e=>e.currentTarget.style.background="transparent"}>▶ Watch Trailer</a>
              {/* Watch Together flag */}
              <button onClick={()=>onWatchTogetherChange&&onWatchTogetherChange(!watchTogether)}
                style={{display:"inline-flex",alignItems:"center",gap:5,fontFamily:"'Courier New',monospace",fontSize:"0.6rem",letterSpacing:"0.08em",textTransform:"uppercase",padding:"5px 12px",borderRadius:3,border:`1px solid ${watchTogether?"rgba(109,255,170,0.5)":"rgba(255,255,255,0.12)"}`,background:watchTogether?"rgba(109,255,170,0.1)":"transparent",color:watchTogether?"#6dffaa":"#4a4a5e",cursor:"pointer",transition:"all 0.15s"}}>
                👥 {watchTogether?"Want to Watch Together":"Watch Together?"}
              </button>
            </div>
          </div>
        </div>

        <div style={{padding:"18px 20px 22px",borderTop:"1px solid rgba(255,255,255,0.06)",display:"flex",flexDirection:"column",gap:16}}>

          {/* Streaming availability */}
          <div>
            <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:10}}>
              <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.15em",color:"#4a4a5e",textTransform:"uppercase"}}>
                Where to Watch
                {providersLoading&&<span style={{marginLeft:8,opacity:0.5}}>...</span>}
              </div>
              {/* JustWatch link — always shown */}
              {jwLink&&(
                <a href={jwLink} target="_blank" rel="noopener"
                  style={{display:"inline-flex",alignItems:"center",gap:5,fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.08em",color:"#f5c518",textDecoration:"none",border:"1px solid rgba(245,197,24,0.3)",padding:"4px 10px",borderRadius:4,transition:"all 0.15s",whiteSpace:"nowrap"}}
                  onMouseEnter={e=>{e.currentTarget.style.background="rgba(245,197,24,0.1)";e.currentTarget.style.borderColor="#f5c518";}}
                  onMouseLeave={e=>{e.currentTarget.style.background="transparent";e.currentTarget.style.borderColor="rgba(245,197,24,0.3)";}}>
                  <svg viewBox="0 0 24 24" fill="currentColor" width="12" height="12"><path d="M10 6v2H5v11h11v-5h2v7H3V6h7zm11-3v8h-2V6.413l-7.793 7.794-1.414-1.414L17.585 5H13V3h8z"/></svg>
                  JustWatch ↗
                </a>
              )}
            </div>
            {!providersLoading && Object.keys(mergedLinks).filter(k=>k!=="custom"&&mergedLinks[k]).length===0 && !mergedLinks.custom ? (
              <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.6rem",color:"#4a4a5e",fontStyle:"italic"}}>
                Not found on major platforms — check JustWatch above or add a custom link below
              </div>
            ) : (
              <div style={{display:"flex",flexWrap:"wrap",gap:8,alignItems:"center"}}>
                {PLATFORMS.filter(p=>mergedLinks[p.id]).map(p=>(
                  <a key={p.id} href={mergedLinks[p.id]} target="_blank" rel="noopener"
                    title={`Watch on ${p.label}`}
                    style={{display:"flex",alignItems:"center",gap:6,padding:"7px 12px",borderRadius:6,background:p.bg,border:`1px solid ${p.color}66`,color:p.color,textDecoration:"none",fontFamily:"'Courier New',monospace",fontSize:"0.62rem",letterSpacing:"0.05em",transition:"all 0.15s"}}
                    onMouseEnter={e=>{e.currentTarget.style.borderColor=p.color;e.currentTarget.style.boxShadow=`0 0 12px ${p.color}44`;e.currentTarget.style.transform="translateY(-1px)";}}
                    onMouseLeave={e=>{e.currentTarget.style.borderColor=`${p.color}66`;e.currentTarget.style.boxShadow="none";e.currentTarget.style.transform="none";}}>
                    {p.icon}
                    <span>{p.label}</span>
                    <span style={{fontSize:"0.5rem",opacity:0.6}}>↗</span>
                  </a>
                ))}
              </div>
            )}
            {/* Custom URL */}
            <div style={{marginTop:12,display:"flex",gap:8,alignItems:"center"}}>
              <input
                defaultValue={streamingLinks?.custom||""}
                placeholder="+ Custom URL (Kanopy, Hoopla, etc.)"
                onBlur={e=>{
                  const val=e.target.value.trim();
                  const next={...(streamingLinks||{})};
                  if(val) next.custom=val; else delete next.custom;
                  onStreamingChange(next);
                }}
                style={{flex:1,background:"rgba(255,255,255,0.03)",border:"1px solid rgba(255,255,255,0.1)",borderRadius:4,padding:"7px 10px",color:"#ede0cc",fontFamily:"'Courier New',monospace",fontSize:"0.65rem",outline:"none"}} />
              {streamingLinks?.custom&&(
                <a href={streamingLinks.custom} target="_blank" rel="noopener"
                  style={{fontFamily:"'Courier New',monospace",fontSize:"0.6rem",color:"#f5c518",textDecoration:"none",border:"1px solid rgba(245,197,24,0.3)",padding:"7px 12px",borderRadius:4,whiteSpace:"nowrap",transition:"all 0.15s"}}
                  onMouseEnter={e=>e.currentTarget.style.background="rgba(245,197,24,0.1)"} onMouseLeave={e=>e.currentTarget.style.background="transparent"}>
                  Open ↗
                </a>
              )}
            </div>
          </div>

          {/* Your Rating */}
          <div>
            <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.15em",color:"#4a4a5e",textTransform:"uppercase",marginBottom:7}}>Your Rating</div>
            <div style={{display:"flex",gap:4}}>
              {[1,2,3,4,5].map(n=>(<button key={n} onClick={()=>onRatingChange(n===rating?0:n)} style={{background:"none",border:"none",cursor:"pointer",padding:0,fontSize:"1.4rem",color:n<=rating?"#f5c518":"#222232",transition:"all 0.15s",transform:n<=rating?"scale(1.12)":"scale(1)"}}>★</button>))}
            </div>
          </div>

          {/* Friends' Ratings */}
          {friendsRatings?.length>0&&(
            <div>
              <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.15em",color:"#4a4a5e",textTransform:"uppercase",marginBottom:8}}>Friends' Ratings</div>
              <div style={{display:"flex",flexDirection:"column",gap:6}}>
                {friendsRatings.map((fr,i)=>(
                  <div key={i} style={{display:"flex",alignItems:"center",justifyContent:"space-between"}}>
                    <span style={{fontFamily:"'Courier New',monospace",fontSize:"0.65rem",color:"#ede0cc"}}>{fr.name}</span>
                    <div style={{display:"flex",gap:2}}>
                      {[1,2,3,4,5].map(n=>(
                        <span key={n} style={{fontSize:"0.9rem",color:n<=fr.rating?"#f5c518":"#222232"}}>★</span>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Notes */}
          <div>
            <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.15em",color:"#4a4a5e",textTransform:"uppercase",marginBottom:7}}>Notes</div>
            <textarea value={localNote} onChange={e=>{ setLocalNote(e.target.value); onNoteChange(e.target.value); }} placeholder="📝 thoughts, reactions, hot takes..." rows={3}
              style={{width:"100%",background:"rgba(255,255,255,0.03)",border:"1px solid rgba(255,255,255,0.08)",borderRadius:4,color:"#ede0cc",fontFamily:"'Courier New',monospace",fontSize:"0.7rem",padding:"10px 12px",resize:"vertical",outline:"none",lineHeight:1.6,boxSizing:"border-box"}} />
          </div>

          {/* Shared custom URL — visible to all friends */}
          <div>
            <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.15em",color:"#4a4a5e",textTransform:"uppercase",marginBottom:7}}>
              Shared Link <span style={{opacity:0.5,fontStyle:"italic",textTransform:"none",letterSpacing:0}}>· visible to everyone</span>
            </div>
            <div style={{display:"flex",gap:8,alignItems:"center"}}>
              <input defaultValue={sharedCustomUrl||""}
                placeholder="Paste a link for the group (e.g. Kanopy, Tubi...)"
                onBlur={e=>onSharedCustomUrlChange&&onSharedCustomUrlChange(e.target.value.trim())}
                style={{flex:1,background:"rgba(255,255,255,0.03)",border:"1px solid rgba(109,255,170,0.2)",borderRadius:4,padding:"7px 10px",color:"#ede0cc",fontFamily:"'Courier New',monospace",fontSize:"0.65rem",outline:"none"}} />
              {sharedCustomUrl&&(
                <a href={sharedCustomUrl} target="_blank" rel="noopener"
                  style={{fontFamily:"'Courier New',monospace",fontSize:"0.6rem",color:"#6dffaa",textDecoration:"none",border:"1px solid rgba(109,255,170,0.3)",padding:"7px 12px",borderRadius:4,whiteSpace:"nowrap",transition:"all 0.15s"}}
                  onMouseEnter={e=>e.currentTarget.style.background="rgba(109,255,170,0.1)"} onMouseLeave={e=>e.currentTarget.style.background="transparent"}>
                  Open ↗
                </a>
              )}
            </div>
          </div>

          {/* Comments & Reactions */}
          {currentUser && <CommentsSection filmTitle={film.t} currentUser={currentUser} darkMode={darkMode} />}

          {/* Actions */}
          <div style={{display:"flex",gap:10,alignItems:"center"}}>
            <button onClick={onToggle}
              style={{flex:1,fontFamily:"'Courier New',monospace",fontSize:"0.7rem",letterSpacing:"0.15em",textTransform:"uppercase",padding:"12px",borderRadius:4,cursor:"pointer",border:"none",background:isWatched?"rgba(245,197,24,0.1)":"#f5c518",color:isWatched?"#f5c518":"#0a0a0d",fontWeight:"bold",transition:"all 0.2s"}}
              onMouseEnter={e=>{ if(isWatched){e.currentTarget.style.background="rgba(230,57,70,0.15)";e.currentTarget.style.color="#e63946";}}}
              onMouseLeave={e=>{ e.currentTarget.style.background=isWatched?"rgba(245,197,24,0.1)":"#f5c518";e.currentTarget.style.color=isWatched?"#f5c518":"#0a0a0d";}}>
              {isWatched?"✓ Watched — Mark Unwatched":"Mark as Watched"}
            </button>
            {isCustom&&(<button onClick={onDelete} style={{background:"none",border:"1px solid rgba(230,57,70,0.25)",color:"#e63946",borderRadius:4,padding:"12px 16px",cursor:"pointer",fontFamily:"'Courier New',monospace",fontSize:"0.65rem",letterSpacing:"0.1em"}}>Remove</button>)}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── FRIEND PROFILE MODAL ─────────────────────
function FriendProfileModal({ userId, displayName, onClose, darkMode }) {
  const [films, setFilms] = useState([]);
  const [loading, setLoading] = useState(true);
  const BG = darkMode ? "#111116" : "#fff";
  const FG = darkMode ? "#ede0cc" : "#1a1a1a";
  const MUTED = darkMode ? "#4a4a5e" : "#888";

  useEffect(() => {
    async function load() {
      const { data } = await supabase.from("user_films").select("*").eq("user_id", userId).eq("watched", true);
      setFilms(data || []);
      setLoading(false);
    }
    load();
    const h = e => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", h);
    return () => window.removeEventListener("keydown", h);
  }, [userId]);

  return (
    <div onClick={e => e.target === e.currentTarget && onClose()}
      style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.88)", zIndex:25000, display:"flex", alignItems:"center", justifyContent:"center", padding:20, backdropFilter:"blur(10px)" }}>
      <div style={{ background:BG, border:"1px solid rgba(245,197,24,0.2)", borderRadius:10, width:"100%", maxWidth:560, maxHeight:"85vh", overflowY:"auto", position:"relative", animation:"modalIn 0.25s cubic-bezier(0.34,1.56,0.64,1)" }}>
        <button onClick={onClose} style={{ position:"absolute", top:14, right:14, background:"none", border:"none", color:MUTED, fontSize:"1.2rem", cursor:"pointer", zIndex:1 }}>✕</button>
        <div style={{ padding:"24px 24px 16px" }}>
          <div style={{ display:"flex", alignItems:"center", gap:14, marginBottom:20 }}>
            <div style={{ width:48, height:48, borderRadius:"50%", background:"linear-gradient(135deg,#793473,#f5c518)", display:"flex", alignItems:"center", justifyContent:"center", fontFamily:"'Impact',sans-serif", fontSize:"1.3rem", color:"#0a0a0d", fontWeight:900, flexShrink:0 }}>
              {displayName.charAt(0).toUpperCase()}
            </div>
            <div>
              <div style={{ fontFamily:"'Impact','Arial Black',sans-serif", fontSize:"1.3rem", color:"#f5c518", textTransform:"uppercase" }}>{displayName}</div>
              <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", color:MUTED, letterSpacing:"0.12em" }}>{films.length} films watched</div>
            </div>
          </div>
          {loading ? (
            <div style={{ textAlign:"center", padding:40, fontFamily:"'Courier New',monospace", fontSize:"0.65rem", color:MUTED }}>Loading...</div>
          ) : films.length === 0 ? (
            <div style={{ textAlign:"center", padding:40, fontFamily:"'Courier New',monospace", fontSize:"0.65rem", color:MUTED }}>Nothing watched yet.</div>
          ) : (
            <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
              {films.map((f, i) => (
                <div key={i} style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"8px 12px", background:darkMode?"rgba(255,255,255,0.03)":"rgba(0,0,0,0.04)", borderRadius:6, border:`1px solid ${darkMode?"rgba(255,255,255,0.06)":"rgba(0,0,0,0.08)"}` }}>
                  <span style={{ fontFamily:"'Georgia',serif", fontSize:"0.82rem", color:FG }}>{f.film_title}</span>
                  <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                    {f.rating > 0 && <span style={{ color:"#f5c518", fontSize:"0.75rem" }}>{"★".repeat(f.rating)}</span>}
                    <span style={{ fontSize:"0.8rem" }}>✓</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ── COMMENTS SECTION ─────────────────────────
function CommentsSection({ filmTitle, currentUser, darkMode }) {
  const [comments, setComments] = useState([]);
  const [newComment, setNewComment] = useState("");
  const [loading, setLoading] = useState(true);
  const EMOJI_REACTIONS = ["🔥","💀","😭","🤌","👏","💯","😂","❤️"];
  const displayName = currentUser.user_metadata?.display_name || currentUser.email?.split("@")[0] || "you";
  const BG = darkMode ? "rgba(255,255,255,0.03)" : "rgba(0,0,0,0.03)";
  const FG = darkMode ? "#ede0cc" : "#1a1a1a";
  const MUTED = darkMode ? "#4a4a5e" : "#888";
  const BORDER = darkMode ? "rgba(255,255,255,0.07)" : "rgba(0,0,0,0.08)";

  useEffect(() => {
    loadComments();
    const ch = supabase.channel(`comments-${filmTitle}`)
      .on("postgres_changes", { event:"*", schema:"public", table:"film_comments", filter:`film_title=eq.${filmTitle}` }, () => loadComments())
      .subscribe();
    return () => supabase.removeChannel(ch);
  }, [filmTitle]);

  async function loadComments() {
    const { data } = await supabase.from("film_comments").select("*").eq("film_title", filmTitle).order("created_at", { ascending:true });
    setComments(data || []);
    setLoading(false);
  }

  async function postComment() {
    if (!newComment.trim()) return;
    await supabase.from("film_comments").insert({ user_id:currentUser.id, display_name:displayName, film_title:filmTitle, comment:newComment.trim(), reactions:{} });
    setNewComment("");
  }

  async function addReaction(commentId, emoji) {
    const comment = comments.find(c => c.id === commentId);
    if (!comment) return;
    const reactions = { ...(comment.reactions || {}) };
    const key = emoji;
    const users = reactions[key] || [];
    if (users.includes(currentUser.id)) {
      reactions[key] = users.filter(u => u !== currentUser.id);
      if (!reactions[key].length) delete reactions[key];
    } else {
      reactions[key] = [...users, currentUser.id];
    }
    await supabase.from("film_comments").update({ reactions }).eq("id", commentId);
  }

  async function deleteComment(id) {
    await supabase.from("film_comments").delete().eq("id", id);
  }

  return (
    <div>
      <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.58rem", letterSpacing:"0.15em", color:MUTED, textTransform:"uppercase", marginBottom:10 }}>
        Comments {comments.length > 0 && `· ${comments.length}`}
      </div>
      {loading ? (
        <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", color:MUTED }}>...</div>
      ) : comments.length === 0 ? (
        <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", color:MUTED, fontStyle:"italic" }}>No comments yet. Be the first!</div>
      ) : (
        <div style={{ display:"flex", flexDirection:"column", gap:8, marginBottom:10 }}>
          {comments.map(c => (
            <div key={c.id} style={{ background:BG, border:`1px solid ${BORDER}`, borderRadius:6, padding:"8px 10px" }}>
              <div style={{ display:"flex", alignItems:"baseline", justifyContent:"space-between", marginBottom:4 }}>
                <span style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", color:"#f5c518", fontWeight:"bold" }}>{c.display_name}</span>
                <div style={{ display:"flex", gap:6, alignItems:"center" }}>
                  <span style={{ fontFamily:"'Courier New',monospace", fontSize:"0.52rem", color:MUTED }}>{new Date(c.created_at).toLocaleDateString()}</span>
                  {c.user_id === currentUser.id && (
                    <button onClick={() => deleteComment(c.id)} style={{ background:"none", border:"none", color:MUTED, cursor:"pointer", fontSize:"0.65rem", padding:0, lineHeight:1 }}>✕</button>
                  )}
                </div>
              </div>
              {c.comment && <div style={{ fontFamily:"'Georgia',serif", fontSize:"0.78rem", color:FG, lineHeight:1.5, marginBottom:6 }}>{c.comment}</div>}
              {/* Reactions */}
              <div style={{ display:"flex", gap:4, flexWrap:"wrap", alignItems:"center" }}>
                {EMOJI_REACTIONS.map(emoji => {
                  const users = c.reactions?.[emoji] || [];
                  const reacted = users.includes(currentUser.id);
                  return (
                    <button key={emoji} onClick={() => addReaction(c.id, emoji)}
                      style={{ background: reacted ? "rgba(245,197,24,0.15)" : BG, border:`1px solid ${reacted?"rgba(245,197,24,0.4)":BORDER}`, borderRadius:12, padding:"2px 7px", cursor:"pointer", fontSize:"0.75rem", display:"flex", alignItems:"center", gap:3, transition:"all 0.15s" }}>
                      {emoji}{users.length > 0 && <span style={{ fontFamily:"'Courier New',monospace", fontSize:"0.55rem", color:reacted?"#f5c518":MUTED }}>{users.length}</span>}
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
      {/* New comment input */}
      <div style={{ display:"flex", gap:6 }}>
        <input value={newComment} onChange={e => setNewComment(e.target.value)}
          onKeyDown={e => e.key === "Enter" && postComment()}
          placeholder="Add a comment..."
          style={{ flex:1, background:BG, border:`1px solid ${BORDER}`, borderRadius:4, padding:"7px 10px", color:FG, fontFamily:"'Courier New',monospace", fontSize:"0.65rem", outline:"none" }} />
        <button onClick={postComment} disabled={!newComment.trim()}
          style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", letterSpacing:"0.1em", textTransform:"uppercase", padding:"7px 12px", border:"none", background:newComment.trim()?"#f5c518":"rgba(255,255,255,0.1)", color:newComment.trim()?"#0a0a0d":MUTED, borderRadius:4, cursor:newComment.trim()?"pointer":"default", fontWeight:"bold", transition:"all 0.15s" }}>
          Post
        </button>
      </div>
    </div>
  );
}

// ── ACTIVITY FEED ─────────────────────────────
function ActivityFeed({ feed, onClickFriend }) {
  if(!feed.length) return null;
  return(
    <div style={{maxWidth:1100,margin:"0 auto 24px",padding:"0 24px"}}>
      <div style={{border:"1px solid rgba(245,197,24,0.1)",borderRadius:6,padding:"11px 18px",background:"rgba(245,197,24,0.02)",display:"flex",gap:20,overflowX:"auto",alignItems:"center"}}>
        <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.56rem",letterSpacing:"0.2em",color:"#4a4a5e",textTransform:"uppercase",flexShrink:0}}>Live</div>
        <div style={{display:"flex",gap:18,alignItems:"center"}}>
          {feed.slice(0,6).map((item,i)=>(
            <div key={i} style={{fontFamily:"'Courier New',monospace",fontSize:"0.6rem",color:"#6e6e88",display:"flex",gap:5,alignItems:"center",whiteSpace:"nowrap"}}>
              <span style={{color:"#f5c518",opacity:0.5}}>▶</span>
              <span onClick={()=>onClickFriend&&item.user_id&&onClickFriend(item.user_id,item.display_name)}
                style={{color:"#ede0cc",opacity:0.8,cursor:onClickFriend?"pointer":"default",textDecoration:onClickFriend?"underline":"none",textDecorationColor:"rgba(237,224,204,0.3)"}}
                onMouseEnter={e=>{if(onClickFriend)e.target.style.color="#f5c518";}} onMouseLeave={e=>{e.target.style.color="";e.target.style.opacity="0.8";}}>
                {item.display_name}
              </span>
              <span>{item.action==="watched"?"watched":item.action==="added"?"added":"rated"}</span>
              <span style={{color:"#ede0cc",opacity:0.5,fontStyle:"italic",maxWidth:110,overflow:"hidden",textOverflow:"ellipsis"}}>{item.film_title}</span>
              {item.rating&&<span style={{color:"#f5c518"}}>{"★".repeat(item.rating)}</span>}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── WATCH PARTY ───────────────────────────────
function WatchParty({ user, allFilms, onClose }) {
  const [screen, setScreen] = useState("lobby"); // lobby | room
  const [roomCode, setRoomCode] = useState("");
  const [joinCode, setJoinCode] = useState("");
  const [party, setParty] = useState(null);
  const [members, setMembers] = useState([]);
  const [votes, setVotes] = useState([]);
  const [myVote, setMyVote] = useState(null);
  const [trailerKey, setTrailerKey] = useState(null);
  const [playback, setPlayback] = useState({ playing: false, time: 0 });
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(false);
  const playerRef = useRef(null);
  const channelRef = useRef(null);
  const displayName = user.user_metadata?.display_name || user.email?.split("@")[0] || "Guest";

  // Unwatched films for voting
  const votableFilms = allFilms.slice(0, 20);

  useEffect(() => {
    const h = e => { if (e.key === "Escape") handleLeave(); };
    window.addEventListener("keydown", h);
    return () => window.removeEventListener("keydown", h);
  }, [party]);

  function generateCode() {
    return Math.random().toString(36).substring(2, 8).toUpperCase();
  }

  async function createRoom() {
    setLoading(true); setStatus(null);
    const code = generateCode();
    const { data, error } = await supabase.from("watch_parties").insert({
      room_code: code, host_id: user.id, host_name: displayName, status: "voting"
    }).select().single();
    if (error) { setStatus("Failed to create room."); setLoading(false); return; }
    await supabase.from("watch_party_members").insert({ party_id: data.id, user_id: user.id, display_name: displayName });
    setParty(data); setRoomCode(code); setScreen("room");
    subscribeToParty(data.id);
    setLoading(false);
  }

  async function joinRoom() {
    if (!joinCode.trim()) return;
    setLoading(true); setStatus(null);
    const { data: partyData, error } = await supabase.from("watch_parties").select("*").eq("room_code", joinCode.toUpperCase()).single();
    if (error || !partyData) { setStatus("Room not found. Check the code and try again."); setLoading(false); return; }
    if (partyData.status === "ended") { setStatus("This party has ended."); setLoading(false); return; }
    await supabase.from("watch_party_members").upsert({ party_id: partyData.id, user_id: user.id, display_name: displayName }, { onConflict: "party_id,user_id" });
    setParty(partyData); setRoomCode(partyData.room_code); setScreen("room");
    subscribeToParty(partyData.id);
    // Load existing votes
    const { data: voteData } = await supabase.from("watch_party_votes").select("*").eq("party_id", partyData.id);
    if (voteData) {
      setVotes(voteData);
      const mine = voteData.find(v => v.user_id === user.id);
      if (mine) setMyVote(mine.film_title);
    }
    if (partyData.winning_film) fetchTrailer(partyData.winning_film);
    setLoading(false);
  }

  function subscribeToParty(partyId) {
    // Load initial members
    supabase.from("watch_party_members").select("*").eq("party_id", partyId).then(({ data }) => { if (data) setMembers(data); });

    const ch = supabase.channel(`party-${partyId}`)
      .on("postgres_changes", { event: "*", schema: "public", table: "watch_parties", filter: `id=eq.${partyId}` }, ({ new: p }) => {
        setParty(p);
        if (p.winning_film) fetchTrailer(p.winning_film);
        if (p.playback_state) setPlayback(p.playback_state);
      })
      .on("postgres_changes", { event: "*", schema: "public", table: "watch_party_members", filter: `party_id=eq.${partyId}` }, () => {
        supabase.from("watch_party_members").select("*").eq("party_id", partyId).then(({ data }) => { if (data) setMembers(data); });
      })
      .on("postgres_changes", { event: "*", schema: "public", table: "watch_party_votes", filter: `party_id=eq.${partyId}` }, () => {
        supabase.from("watch_party_votes").select("*").eq("party_id", partyId).then(({ data }) => { if (data) setVotes(data); });
      })
      .subscribe();
    channelRef.current = ch;
  }

  async function fetchTrailer(filmTitle) {
    const data = await fetchTMDBBackdrop({ t: filmTitle });
    if (data?.youtubeKey) setTrailerKey(data.youtubeKey);
  }

  async function castVote(filmTitle) {
    if (!party) return;
    setMyVote(filmTitle);
    await supabase.from("watch_party_votes").upsert({ party_id: party.id, user_id: user.id, film_title: filmTitle }, { onConflict: "party_id,user_id" });
  }

  async function lockInWinner() {
    if (!party || party.host_id !== user.id) return;
    // Tally votes
    const tally = {};
    votes.forEach(v => { tally[v.film_title] = (tally[v.film_title] || 0) + 1; });
    const winner = Object.entries(tally).sort((a, b) => b[1] - a[1])[0]?.[0];
    if (!winner) return;
    await supabase.from("watch_parties").update({ status: "watching", winning_film: winner }).eq("id", party.id);
  }

  async function updatePlayback(playing, time) {
    if (!party || party.host_id !== user.id) return;
    const state = { playing, time, updatedAt: Date.now() };
    await supabase.from("watch_parties").update({ playback_state: state }).eq("id", party.id);
  }

  async function handleLeave() {
    if (party) {
      await supabase.from("watch_party_members").delete().eq("party_id", party.id).eq("user_id", user.id);
      if (party.host_id === user.id) await supabase.from("watch_parties").update({ status: "ended" }).eq("id", party.id);
    }
    if (channelRef.current) supabase.removeChannel(channelRef.current);
    onClose();
  }

  // Vote tallying
  const tally = {};
  votes.forEach(v => { tally[v.film_title] = (tally[v.film_title] || 0) + 1; });
  const sortedFilms = [...votableFilms].sort((a, b) => (tally[b.t] || 0) - (tally[a.t] || 0));
  const isHost = party?.host_id === user.id;
  const winner = party?.winning_film;

  // JustWatch link for winner
  const jwWinnerLink = winner ? `https://www.justwatch.com/us/search?q=${encodeURIComponent(cleanTitle(winner))}` : null;

  return (
    <div onClick={e => e.target === e.currentTarget && handleLeave()}
      style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.92)", zIndex:20000, display:"flex", alignItems:"center", justifyContent:"center", padding:20, backdropFilter:"blur(12px)" }}>
      <div style={{ background:"#0f0f14", border:"1px solid rgba(109,255,170,0.25)", borderRadius:12, width:"100%", maxWidth: screen==="room" ? 700 : 420, maxHeight:"90vh", overflowY:"auto", position:"relative", animation:"modalIn 0.25s cubic-bezier(0.34,1.56,0.64,1)" }}>

        {/* Header */}
        <div style={{ padding:"20px 24px 16px", borderBottom:"1px solid rgba(255,255,255,0.06)", display:"flex", alignItems:"center", justifyContent:"space-between" }}>
          <div>
            <div style={{ fontFamily:"'Impact','Arial Black',sans-serif", fontSize:"1.3rem", color:"#6dffaa", letterSpacing:"0.02em" }}>🎉 Watch Party</div>
            {party && <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", color:"#4a4a5e", letterSpacing:"0.2em", marginTop:2 }}>ROOM: {roomCode} &nbsp;·&nbsp; {members.length} member{members.length!==1?"s":""}</div>}
          </div>
          <button onClick={handleLeave} style={{ background:"none", border:"none", color:"#4a4a5e", fontSize:"1.2rem", cursor:"pointer", padding:4 }} onMouseEnter={e=>e.target.style.color="#ede0cc"} onMouseLeave={e=>e.target.style.color="#4a4a5e"}>✕</button>
        </div>

        {/* Lobby */}
        {screen === "lobby" && (
          <div style={{ padding:32, display:"flex", flexDirection:"column", gap:24 }}>
            <div style={{ textAlign:"center" }}>
              <div style={{ fontSize:"3rem", marginBottom:12 }}>🍿</div>
              <div style={{ fontFamily:"'Georgia',serif", fontSize:"0.9rem", color:"#6e6e88", fontStyle:"italic", lineHeight:1.6 }}>
                Create a room and share the code with friends, or join an existing party.
              </div>
            </div>
            <button onClick={createRoom} disabled={loading}
              style={{ width:"100%", fontFamily:"'Courier New',monospace", fontSize:"0.72rem", letterSpacing:"0.18em", textTransform:"uppercase", padding:"14px", borderRadius:6, cursor:"pointer", border:"none", background:"#6dffaa", color:"#0a0a0d", fontWeight:"bold", opacity:loading?0.6:1, transition:"all 0.2s" }}
              onMouseEnter={e=>e.currentTarget.style.background="#50ffaa"} onMouseLeave={e=>e.currentTarget.style.background="#6dffaa"}>
              {loading ? "Creating..." : "🎬 Create a Room"}
            </button>
            <div style={{ display:"flex", alignItems:"center", gap:12 }}>
              <div style={{ flex:1, height:1, background:"rgba(255,255,255,0.08)" }} />
              <span style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", color:"#4a4a5e", letterSpacing:"0.15em" }}>OR</span>
              <div style={{ flex:1, height:1, background:"rgba(255,255,255,0.08)" }} />
            </div>
            <div style={{ display:"flex", gap:8 }}>
              <input value={joinCode} onChange={e=>setJoinCode(e.target.value.toUpperCase())} placeholder="Enter room code"
                onKeyDown={e=>e.key==="Enter"&&joinRoom()}
                style={{ flex:1, background:"rgba(255,255,255,0.04)", border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, padding:"12px 14px", color:"#ede0cc", fontFamily:"'Courier New',monospace", fontSize:"0.85rem", outline:"none", letterSpacing:"0.2em", textTransform:"uppercase" }} />
              <button onClick={joinRoom} disabled={loading}
                style={{ fontFamily:"'Courier New',monospace", fontSize:"0.68rem", letterSpacing:"0.12em", textTransform:"uppercase", padding:"12px 20px", borderRadius:6, cursor:"pointer", border:"1px solid rgba(109,255,170,0.35)", background:"rgba(109,255,170,0.08)", color:"#6dffaa", fontWeight:"bold", whiteSpace:"nowrap" }}>
                Join →
              </button>
            </div>
            {status && <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.65rem", color:"#ff8888", textAlign:"center" }}>{status}</div>}
          </div>
        )}

        {/* Room */}
        {screen === "room" && party && (
          <div style={{ padding:24, display:"flex", flexDirection:"column", gap:20 }}>

            {/* Members */}
            <div>
              <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.58rem", letterSpacing:"0.2em", color:"#4a4a5e", textTransform:"uppercase", marginBottom:10 }}>In the Room</div>
              <div style={{ display:"flex", gap:8, flexWrap:"wrap" }}>
                {members.map(m => (
                  <div key={m.id} style={{ display:"flex", alignItems:"center", gap:6, background:"rgba(255,255,255,0.05)", border:"1px solid rgba(255,255,255,0.1)", borderRadius:20, padding:"4px 12px" }}>
                    <div style={{ width:22, height:22, borderRadius:"50%", background:"linear-gradient(135deg,#793473,#6dffaa)", display:"flex", alignItems:"center", justifyContent:"center", fontFamily:"'Impact',sans-serif", fontSize:"0.7rem", color:"#0a0a0d", fontWeight:900 }}>{m.display_name.charAt(0).toUpperCase()}</div>
                    <span style={{ fontFamily:"'Courier New',monospace", fontSize:"0.62rem", color:"#ede0cc" }}>{m.display_name}</span>
                    {m.user_id === party.host_id && <span style={{ fontSize:"0.5rem", color:"#f5c518" }}>HOST</span>}
                  </div>
                ))}
              </div>
            </div>

            {/* Share code */}
            <div style={{ background:"rgba(109,255,170,0.05)", border:"1px solid rgba(109,255,170,0.2)", borderRadius:6, padding:"12px 16px", display:"flex", alignItems:"center", justifyContent:"space-between" }}>
              <div>
                <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.55rem", color:"#4a4a5e", letterSpacing:"0.15em", textTransform:"uppercase", marginBottom:4 }}>Share this code</div>
                <div style={{ fontFamily:"'Impact','Arial Black',sans-serif", fontSize:"1.8rem", color:"#6dffaa", letterSpacing:"0.15em" }}>{roomCode}</div>
              </div>
              <button onClick={()=>navigator.clipboard?.writeText(roomCode).then(()=>{})}
                style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", letterSpacing:"0.1em", textTransform:"uppercase", padding:"8px 14px", border:"1px solid rgba(109,255,170,0.3)", background:"transparent", color:"#6dffaa", borderRadius:4, cursor:"pointer" }}>
                Copy
              </button>
            </div>

            {/* Winning film / trailer */}
            {winner && (
              <div style={{ background:"rgba(245,197,24,0.06)", border:"1px solid rgba(245,197,24,0.3)", borderRadius:8, padding:16 }}>
                <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.58rem", color:"#f5c518", letterSpacing:"0.2em", textTransform:"uppercase", marginBottom:8 }}>🏆 Tonight's Pick</div>
                <div style={{ fontFamily:"'Impact','Arial Black',sans-serif", fontSize:"1.3rem", color:"#ede0cc", marginBottom:12 }}>{winner}</div>
                {trailerKey && (
                  <div style={{ borderRadius:6, overflow:"hidden", marginBottom:12, position:"relative", paddingBottom:"56.25%", height:0 }}>
                    <iframe src={`https://www.youtube.com/embed/${trailerKey}?rel=0`}
                      style={{ position:"absolute", top:0, left:0, width:"100%", height:"100%" }}
                      allow="fullscreen" allowFullScreen />
                  </div>
                )}
                <div style={{ display:"flex", gap:10 }}>
                  {jwWinnerLink && (
                    <a href={jwWinnerLink} target="_blank" rel="noopener"
                      style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:6, fontFamily:"'Courier New',monospace", fontSize:"0.65rem", letterSpacing:"0.1em", textTransform:"uppercase", padding:"10px", borderRadius:4, background:"#f5c518", color:"#0a0a0d", fontWeight:"bold", textDecoration:"none", transition:"all 0.15s" }}
                      onMouseEnter={e=>e.currentTarget.style.background="#fff"} onMouseLeave={e=>e.currentTarget.style.background="#f5c518"}>
                      Find on JustWatch ↗
                    </a>
                  )}
                  <a href={`https://www.teleparty.com`} target="_blank" rel="noopener"
                    style={{ flex:1, display:"flex", alignItems:"center", justifyContent:"center", gap:6, fontFamily:"'Courier New',monospace", fontSize:"0.65rem", letterSpacing:"0.1em", textTransform:"uppercase", padding:"10px", borderRadius:4, border:"1px solid rgba(255,255,255,0.2)", color:"#ede0cc", textDecoration:"none", transition:"all 0.15s" }}
                    onMouseEnter={e=>e.currentTarget.style.background="rgba(255,255,255,0.08)"} onMouseLeave={e=>e.currentTarget.style.background="transparent"}>
                    Sync via Teleparty ↗
                  </a>
                </div>
              </div>
            )}

            {/* Voting */}
            {party.status === "voting" && (
              <div>
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:12 }}>
                  <div style={{ fontFamily:"'Courier New',monospace", fontSize:"0.58rem", letterSpacing:"0.2em", color:"#4a4a5e", textTransform:"uppercase" }}>
                    Vote — What do we watch? ({votes.length}/{members.length} voted)
                  </div>
                  {isHost && votes.length > 0 && (
                    <button onClick={lockInWinner}
                      style={{ fontFamily:"'Courier New',monospace", fontSize:"0.6rem", letterSpacing:"0.1em", textTransform:"uppercase", padding:"6px 14px", border:"none", background:"#6dffaa", color:"#0a0a0d", borderRadius:4, cursor:"pointer", fontWeight:"bold" }}>
                      Lock In Winner 🔒
                    </button>
                  )}
                </div>
                <div style={{ display:"flex", flexDirection:"column", gap:6, maxHeight:320, overflowY:"auto" }}>
                  {sortedFilms.map(film => {
                    const voteCount = tally[film.t] || 0;
                    const pct = members.length ? (voteCount / members.length) * 100 : 0;
                    const isMyVote = myVote === film.t;
                    return (
                      <div key={film.t} onClick={() => castVote(film.t)}
                        style={{ display:"flex", alignItems:"center", gap:12, padding:"10px 14px", borderRadius:6, border:`1px solid ${isMyVote?"rgba(109,255,170,0.5)":"rgba(255,255,255,0.06)"}`, background: isMyVote?"rgba(109,255,170,0.06)":"rgba(255,255,255,0.02)", cursor:"pointer", position:"relative", overflow:"hidden", transition:"all 0.15s" }}
                        onMouseEnter={e=>{ if(!isMyVote) e.currentTarget.style.background="rgba(255,255,255,0.05)"; }}
                        onMouseLeave={e=>{ if(!isMyVote) e.currentTarget.style.background="rgba(255,255,255,0.02)"; }}>
                        {/* Vote bar background */}
                        <div style={{ position:"absolute", left:0, top:0, bottom:0, width:`${pct}%`, background:"rgba(109,255,170,0.07)", transition:"width 0.4s", pointerEvents:"none" }} />
                        <span style={{ fontSize:"1rem", flexShrink:0 }}>{film.e}</span>
                        <span style={{ flex:1, fontFamily:"'Georgia',serif", fontSize:"0.8rem", color: isMyVote?"#6dffaa":"#ede0cc", fontWeight: isMyVote?"bold":"normal", position:"relative" }}>{film.t}</span>
                        <div style={{ display:"flex", alignItems:"center", gap:6, flexShrink:0, position:"relative" }}>
                          {voteCount > 0 && <span style={{ fontFamily:"'Courier New',monospace", fontSize:"0.65rem", color:"#6dffaa" }}>{voteCount} vote{voteCount!==1?"s":""}</span>}
                          {isMyVote && <span style={{ fontSize:"0.75rem" }}>✓</span>}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

// ── MAIN APP ──────────────────────────────────
export default function App() {
  const [user,setUser]=useState(null);
  const [authReady,setAuthReady]=useState(false);
  const [watched,setWatched]=useState({});
  const [notes,setNotes]=useState({});
  const [ratings,setRatings]=useState({});
  const [streamingLinks,setStreamingLinks]=useState({});
  const [customFilms,setCustomFilms]=useState([]);
  const [friendsData,setFriendsData]=useState({});
  const [friendsRatings,setFriendsRatings]=useState({});
  const [feed,setFeed]=useState([]);
  const [toast,setToast]=useState(null);
  const [selectedFilm,setSelectedFilm]=useState(null);
  const [addInput,setAddInput]=useState("");
  const [searchResults,setSearchResults]=useState([]);
  const [searchOpen,setSearchOpen]=useState(false);
  const [searchLoading,setSearchLoading]=useState(false);
  const [filter,setFilter]=useState("all");
  const [hiddenFilms,setHiddenFilms]=useState({});
  const [filmOrder,setFilmOrder]=useState([]); // array of film titles in order
  const [dragIndex,setDragIndex]=useState(null);
  const [dragOverIndex,setDragOverIndex]=useState(null);
  const [showWatchParty,setShowWatchParty]=useState(false);
  const [mobileMenuOpen,setMobileMenuOpen]=useState(false);
  const [friendProfile,setFriendProfile]=useState(null); // {userId, displayName}
  const [watchTogether,setWatchTogether]=useState({});
  const [sharedCustomUrls,setSharedCustomUrls]=useState({});
  // Discovery & UI
  const [darkMode,setDarkMode]=useState(true);
  const [gridSize,setGridSize]=useState("md"); // sm | md | lg
  const [sortBy,setSortBy]=useState("default"); // default | rating | genre | added
  const [tagFilter,setTagFilter]=useState(null); // e.g. "thriller"
  const [queueSearch,setQueueSearch]=useState(""); // search within queue
  const [recommendations,setRecommendations]=useState(null); // { film, recs }
  const [showConfetti,setShowConfetti]=useState(false);
  const prevWatchedCount=useRef(0);
  const canvasRef=useRef(null);
  const {burst}=useConfetti(canvasRef);
  const searchTimer=useRef(null);
  const toastTimer=useRef(null);
  const saveOrderTimer=useRef(null);

  useEffect(()=>{
    function resize(){if(canvasRef.current){canvasRef.current.width=window.innerWidth;canvasRef.current.height=window.innerHeight;}}
    resize();window.addEventListener("resize",resize);return()=>window.removeEventListener("resize",resize);
  },[]);

  useEffect(()=>{
    supabase.auth.getSession().then(({data:{session}})=>{setUser(session?.user??null);setAuthReady(true);});
    const{data:{subscription}}=supabase.auth.onAuthStateChange((_,session)=>setUser(session?.user??null));
    return()=>subscription.unsubscribe();
  },[]);

  useEffect(()=>{
    if(!user) return;
    loadUserData();loadSharedFilms();loadFriendsData();loadFeed();
    const ch=supabase.channel("wq-rt")
      .on("postgres_changes",{event:"*",schema:"public",table:"user_films"},()=>{loadFriendsData();loadFeed();})
      .on("postgres_changes",{event:"*",schema:"public",table:"activity_feed"},()=>loadFeed())
      .on("postgres_changes",{event:"*",schema:"public",table:"shared_films"},()=>loadSharedFilms())
      .subscribe();
    return()=>supabase.removeChannel(ch);
  },[user]);

  async function loadSharedFilms(){
    const{data}=await supabase.from("shared_films").select("*").order("created_at",{ascending:true});
    if(!data) return;
    const films=data.map(row=>({
      t:row.film_title, e:row.emoji||"🎬", s:row.summary||"",
      tags:row.tags||[], yt:row.yt||"",
      posterUrl:(row.poster_url&&!row.poster_url.includes("wikipedia")&&!row.poster_url.includes("wikimedia"))?row.poster_url:"",
      note:"", _custom:true, _sharedId:row.id, _addedBy:row.added_by, _addedByName:row.added_by_name,
    }));
    setCustomFilms(films);
    // Re-fetch TMDB poster for any missing ones
    for(const film of films.filter(f=>!f.posterUrl)){
      const src=await fetchTMDBPoster(film.t,"w300");
      if(src){
        setCustomFilms(cf=>cf.map(f=>f.t===film.t?{...f,posterUrl:src}:f));
        await supabase.from("shared_films").update({poster_url:src}).eq("film_title",film.t);
      }
    }
  }

  async function loadUserData(){
    const{data}=await supabase.from("user_films").select("*").eq("user_id",user.id);
    if(!data) return;
    const w={},n={},r={},sl={},hidden={},orderMap={},wt={};
    data.forEach(row=>{
      if(row.hidden) hidden[row.film_title]=true;
      else {
        if(row.watched)w[row.film_title]=true;
        if(row.note)n[row.film_title]=row.note;
        if(row.rating)r[row.film_title]=row.rating;
        if(row.streaming_links)sl[row.film_title]=row.streaming_links;
      }
      if(row.sort_order!=null)orderMap[row.film_title]=row.sort_order;
      if(row.watch_together)wt[row.film_title]=true;
    });
    setWatched(w);setNotes(n);setRatings(r);setStreamingLinks(sl);setHiddenFilms(hidden);setWatchTogether(wt);

    // Load shared custom URLs from ALL users
    const{data:allShared}=await supabase.from("user_films").select("film_title,shared_custom_url").not("shared_custom_url","is",null);
    const scu={};
    (allShared||[]).forEach(row=>{ if(row.shared_custom_url) scu[row.film_title]=row.shared_custom_url; });
    setSharedCustomUrls(scu);

    // Build order from sort_order values — shared films will be appended after
    const coreTitles=FILMS.filter(f=>!hidden[f.t]).map(f=>f.t);
    const sorted=coreTitles.sort((a,b)=>(orderMap[a]??9999)-(orderMap[b]??9999));
    setFilmOrder(sorted);

    // Re-fetch TMDB poster for custom films missing one (handled separately in loadSharedFilms)
  }

  async function loadFriendsData(){
    const{data}=await supabase.from("user_films").select("film_title,user_id,rating").neq("user_id",user.id);
    if(!data||!data.length) return;
    const userIds=[...new Set(data.map(r=>r.user_id))];
    const{data:profiles}=await supabase.from("profiles").select("id,display_name").in("id",userIds);
    const nameMap={};
    (profiles||[]).forEach(p=>nameMap[p.id]=p.display_name||"friend");
    const watchedMap={};
    const ratingsMap={}; // { filmTitle: [{name, rating}] }
    data.forEach(row=>{
      const name=nameMap[row.user_id]||"friend";
      if(row.rating){
        if(!ratingsMap[row.film_title]) ratingsMap[row.film_title]=[];
        ratingsMap[row.film_title].push({name,rating:row.rating});
      }
    });
    // Also load watched separately
    const{data:watchedData}=await supabase.from("user_films").select("film_title,user_id").eq("watched",true).neq("user_id",user.id);
    (watchedData||[]).forEach(row=>{
      const name=nameMap[row.user_id]||"friend";
      if(!watchedMap[row.film_title])watchedMap[row.film_title]=[];
      if(!watchedMap[row.film_title].includes(name))watchedMap[row.film_title].push(name);
    });
    setFriendsData(watchedMap);
    setFriendsRatings(ratingsMap);
  }

  async function loadFeed(){
    const{data}=await supabase.from("activity_feed").select("*").order("created_at",{ascending:false}).limit(12);
    if(data) setFeed(data);
  }

  function showToast(msg){setToast(msg);clearTimeout(toastTimer.current);toastTimer.current=setTimeout(()=>setToast(null),2600);}

  async function toggleWatched(film){
    const title=film.t,wasWatched=!!watched[title];
    const next={...watched};
    if(wasWatched)delete next[title];else next[title]=true;
    setWatched(next);
    await supabase.from("user_films").upsert({user_id:user.id,film_title:title,watched:!wasWatched,emoji:film.e||"🎬",is_custom:!!film._custom},{onConflict:"user_id,film_title"});
    if(!wasWatched){
      burst(window.innerWidth/2,window.innerHeight/2);
      await supabase.from("activity_feed").insert({user_id:user.id,display_name:user.user_metadata?.display_name||"someone",film_title:title,action:"watched"});
      showToast(`✓ ${title} watched!`);
      // Fetch TMDB recommendations
      fetchTMDBRecs(film).then(recs=>{ if(recs?.length) setRecommendations({film,recs}); });
      // Check for 100% completion
      const newCount=Object.keys(next).length;
      if(newCount===totalFilms && newCount>0) setShowConfetti(true);
    }
  }

  async function fetchTMDBRecs(film){
    try{
      const headers={Authorization:`Bearer ${TMDB_TOKEN}`};
      const title=cleanTitle(film.tmdbQuery||film.t);
      const year=extractYear(film.t);
      const r=await fetch(`https://api.themoviedb.org/3/search/movie?query=${encodeURIComponent(title)}&language=en-US&page=1${year?`&year=${year}`:""}&`,{headers});
      const d=await r.json();
      const movieId=d.results?.[0]?.id; if(!movieId) return null;
      const r2=await fetch(`https://api.themoviedb.org/3/movie/${movieId}/recommendations?language=en-US&page=1`,{headers});
      const d2=await r2.json();
      return d2.results?.slice(0,6).map(m=>({
        t:m.title, s:m.overview?.slice(0,120)+"…",
        poster:m.poster_path?`https://image.tmdb.org/t/p/w200${m.poster_path}`:null,
        year:m.release_date?.slice(0,4)||""
      }));
    }catch(_){return null;}
  }

  async function saveNote(title,val){
    setNotes(n=>({...n,[title]:val}));
    await supabase.from("user_films").upsert({user_id:user.id,film_title:title,note:val},{onConflict:"user_id,film_title"});
  }

  async function saveRating(title,val,film){
    setRatings(r=>({...r,[title]:val}));
    await supabase.from("user_films").upsert({user_id:user.id,film_title:title,rating:val,emoji:film.e||"🎬"},{onConflict:"user_id,film_title"});
    if(val) await supabase.from("activity_feed").insert({user_id:user.id,display_name:user.user_metadata?.display_name||"someone",film_title:title,action:"rated",rating:val});
  }

  async function saveStreamingLinks(title,links,film){
    setStreamingLinks(sl=>({...sl,[title]:links}));
    await supabase.from("user_films").upsert({user_id:user.id,film_title:title,streaming_links:links,emoji:film.e||"🎬"},{onConflict:"user_id,film_title"});
  }

  async function saveWatchTogether(title, val) {
    setWatchTogether(wt=>({...wt,[title]:val}));
    await supabase.from("user_films").upsert({user_id:user.id,film_title:title,watch_together:val},{onConflict:"user_id,film_title"});
  }

  async function saveSharedCustomUrl(title, url) {
    setSharedCustomUrls(scu=>({...scu,[title]:url||null}));
    await supabase.from("user_films").upsert({user_id:user.id,film_title:title,shared_custom_url:url||null},{onConflict:"user_id,film_title"});
  }

  async function removeFilm(film){
    if(film._custom){
      if(film._addedBy && film._addedBy !== user.id){
        showToast("Only the person who added this can remove it");
        return;
      }
      setCustomFilms(cf=>cf.filter(f=>f.t!==film.t));
      await supabase.from("shared_films").delete().eq("film_title",film.t);
    } else {
      // Core film -- hide per user via upsert
      const{error}=await supabase.from("user_films").upsert(
        {user_id:user.id,film_title:film.t,hidden:true},
        {onConflict:"user_id,film_title"}
      );
      if(error){
        // Try insert if upsert fails due to RLS
        await supabase.from("user_films").insert({user_id:user.id,film_title:film.t,hidden:true}).maybeSingle();
      }
      setHiddenFilms(h=>({...h,[film.t]:true}));
    }
    setFilmOrder(o=>o.filter(t=>t!==film.t));
    if(selectedFilm?.t===film.t) setSelectedFilm(null);
    showToast(`"${film.t}" removed`);
  }

  // ── DRAG TO REORDER ──
  function handleDragStart(idx){ setDragIndex(idx); }
  function handleDragEnter(idx){ if(idx!==dragIndex) setDragOverIndex(idx); }
  function handleDragEnd(){
    if(dragIndex!=null && dragOverIndex!=null && dragIndex!==dragOverIndex){
      const newOrder=[...filteredFilms.map(f=>f.t)];
      const [moved]=newOrder.splice(dragIndex,1);
      newOrder.splice(dragOverIndex,0,moved);
      // Merge back with unfiltered order
      setFilmOrder(prev=>{
        const filtered=new Set(newOrder);
        const unfiltered=prev.filter(t=>!filtered.has(t));
        return [...newOrder,...unfiltered];
      });
      // Debounce save to Supabase
      clearTimeout(saveOrderTimer.current);
      saveOrderTimer.current=setTimeout(async()=>{
        const upserts=newOrder.map((title,i)=>({user_id:user.id,film_title:title,sort_order:i}));
        for(const row of upserts){
          await supabase.from("user_films").upsert(row,{onConflict:"user_id,film_title"});
        }
      },800);
    }
    setDragIndex(null); setDragOverIndex(null);
  }

  // Search
  useEffect(()=>{
    if(!addInput.trim()){setSearchOpen(false);setSearchResults([]);return;}
    setSearchLoading(true);setSearchOpen(true);
    clearTimeout(searchTimer.current);
    searchTimer.current=setTimeout(async()=>{
      try{
        const params=new URLSearchParams({action:"query",list:"search",srsearch:addInput+" film",srlimit:"6",format:"json",origin:"*"});
        const res=await fetch(`https://en.wikipedia.org/w/api.php?${params}`);
        const data=await res.json();
        const titles=(data.query?.search||[]).map(r=>r.title);
        if(!titles.length){setSearchResults([]);setSearchLoading(false);return;}
        const summaries=await Promise.all(titles.map(t=>fetch(`https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(t.replace(/ /g,"_"))}`).then(r=>r.json()).catch(()=>null)));
        setSearchResults(summaries.filter(Boolean));
      }catch(_){setSearchResults([]);}
      setSearchLoading(false);
    },320);
  },[addInput]);

  async function addFromSearch(page){
    setAddInput("");setSearchOpen(false);
    const raw=(page.extract||page.description||"").replace(/<[^>]+>/g,"");
    const sentences=raw.match(/[^.!?]+[.!?]+/g)||[];
    let pick=sentences;if(sentences.length>1&&/\bis\s+a\b/i.test(sentences[0]))pick=sentences.slice(1);
    let s=pick.slice(0,2).join(" ").trim()||raw.slice(0,220);
    if(s.length>220)s=s.slice(0,217)+"…";
    const tmdbPoster=await fetchTMDBPoster(page.title,"w300");
    const posterUrl=tmdbPoster||page.thumbnail?.source?.replace(/\/\d+px-/,"/300px-")||"";
    const dName=user.user_metadata?.display_name||user.email?.split("@")[0]||"someone";
    // Save to shared_films so ALL users see it
    const{error}=await supabase.from("shared_films").upsert({
      added_by:user.id, added_by_name:dName,
      film_title:page.title, emoji:"🎬", summary:s,
      poster_url:posterUrl, yt:page.title+" official trailer", tags:[]
    },{onConflict:"film_title"});
    if(error){ console.error("shared_films upsert failed:",error); showToast("Could not add film"); return; }
    await supabase.from("activity_feed").insert({user_id:user.id,display_name:dName,film_title:page.title,action:"added"});
    showToast(`"${page.title}" added for everyone! 🎬`);
  }

  async function signOut(){await supabase.auth.signOut();setWatched({});setNotes({});setRatings({});setCustomFilms([]);}
  function copyLink(){navigator.clipboard?.writeText(window.location.href).then(()=>showToast("Link copied! Send to friends 🎬"));}
  async function resetAll(){if(!confirm("Reset all your watched items?"))return;setWatched({});await supabase.from("user_films").update({watched:false}).eq("user_id",user.id);}

  const allFilmsMap = Object.fromEntries([...FILMS,...customFilms].map(f=>[f.t,f]));
  const allFilms = filmOrder.length
    ? [...filmOrder.map(t=>allFilmsMap[t]).filter(Boolean), ...customFilms.filter(f=>!filmOrder.includes(f.t))]
    : [...FILMS.filter(f=>!hiddenFilms[f.t]),...customFilms];

  const gridCols = gridSize==="sm"?"repeat(auto-fill,minmax(90px,1fr))":gridSize==="lg"?"repeat(auto-fill,minmax(180px,1fr))":"repeat(auto-fill,minmax(130px,1fr))";

  // All unique tags across films
  const allTags=[...new Set(allFilms.flatMap(f=>f.tags?.map(([,k])=>k)||[]))];

  let filteredFilms=allFilms.filter(f=>{
    if(hiddenFilms[f.t]) return false;
    if(filter==="watched" && !watched[f.t]) return false;
    if(filter==="unwatched" && watched[f.t]) return false;
    if(tagFilter && !f.tags?.some(([,k])=>k===tagFilter)) return false;
    if(queueSearch && !f.t.toLowerCase().includes(queueSearch.toLowerCase())) return false;
    return true;
  });

  if(sortBy==="rating") filteredFilms=[...filteredFilms].sort((a,b)=>(ratings[b.t]||0)-(ratings[a.t]||0));
  else if(sortBy==="genre") filteredFilms=[...filteredFilms].sort((a,b)=>(a.tags?.[0]?.[0]||"").localeCompare(b.tags?.[0]?.[0]||""));
  else if(sortBy==="added") filteredFilms=[...filteredFilms].reverse();

  const totalFilms=allFilms.filter(f=>!hiddenFilms[f.t]).length;
  const watchedCount=Object.keys(watched).length;
  const displayName=user?.user_metadata?.display_name||user?.email?.split("@")[0]||"you";

  if(!authReady) return(<div style={{background:"#0a0a0d",minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center"}}><div style={{fontFamily:"'Courier New',monospace",color:"#f5c518",fontSize:"0.8rem",letterSpacing:"0.3em"}}>LOADING...</div></div>);
  if(!user) return <AuthModal />;

  const BG=darkMode?"#0a0a0d":"#f4f0e8";
  const FG=darkMode?"#ede0cc":"#1a1a1a";
  const CARD=darkMode?"#111116":"#ffffff";
  const MUTED=darkMode?"#4a4a5e":"#888";

  return(
    <div style={{background:BG,color:FG,fontFamily:"'Georgia','Times New Roman',serif",minHeight:"100vh",overflowX:"hidden",position:"relative",transition:"background 0.3s,color 0.3s"}}>
      <div style={{position:"fixed",inset:0,pointerEvents:"none",zIndex:9999,opacity:0.035,backgroundImage:`url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='400'%3E%3Cfilter id='g'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='400' height='400' filter='url(%23g)'/%3E%3C/svg%3E")`}} />
      {darkMode&&<div style={{position:"fixed",inset:0,background:"repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,0,0,0.06) 2px,rgba(0,0,0,0.06) 4px)",pointerEvents:"none",zIndex:9998}} />}
      <canvas ref={canvasRef} style={{position:"fixed",inset:0,pointerEvents:"none",zIndex:99997}} />

      {/* 100% Completion Celebration */}
      {showConfetti&&(
        <div style={{position:"fixed",inset:0,zIndex:99998,display:"flex",alignItems:"center",justifyContent:"center",background:"rgba(0,0,0,0.85)",backdropFilter:"blur(10px)"}} onClick={()=>setShowConfetti(false)}>
          <div style={{textAlign:"center",animation:"modalIn 0.4s cubic-bezier(0.34,1.56,0.64,1)"}}>
            <div style={{fontSize:"5rem",marginBottom:16,animation:"wobble 1s ease-in-out infinite"}}>🏆</div>
            <div style={{fontFamily:"'Impact','Arial Black',sans-serif",fontSize:"clamp(2rem,6vw,4rem)",color:"#f5c518",textShadow:"2px 2px 0 #7a620a",textTransform:"uppercase",marginBottom:12}}>Queue Complete!</div>
            <div style={{fontFamily:"'Georgia',serif",fontSize:"1rem",color:"#ede0cc",fontStyle:"italic",marginBottom:8}}>You've watched every single film.</div>
            <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.7rem",color:"#4a4a5e",letterSpacing:"0.15em"}}>Certified Cinema Legend 🎬</div>
            <div style={{marginTop:28,fontFamily:"'Courier New',monospace",fontSize:"0.6rem",color:"#4a4a5e",letterSpacing:"0.1em"}}>click anywhere to close</div>
          </div>
        </div>
      )}

      {/* TMDB Recommendations Modal */}
      {recommendations&&(
        <div style={{position:"fixed",inset:0,zIndex:19999,background:"rgba(0,0,0,0.85)",backdropFilter:"blur(8px)",display:"flex",alignItems:"center",justifyContent:"center",padding:20}} onClick={()=>setRecommendations(null)}>
          <div onClick={e=>e.stopPropagation()} style={{background:CARD,border:"1px solid rgba(245,197,24,0.25)",borderRadius:10,width:"100%",maxWidth:620,padding:28,animation:"modalIn 0.25s cubic-bezier(0.34,1.56,0.64,1)"}}>
            <div style={{display:"flex",alignItems:"baseline",justifyContent:"space-between",marginBottom:20}}>
              <div>
                <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.6rem",letterSpacing:"0.2em",color:MUTED,textTransform:"uppercase",marginBottom:4}}>Because you watched</div>
                <div style={{fontFamily:"'Impact','Arial Black',sans-serif",fontSize:"1.3rem",color:"#f5c518"}}>{recommendations.film.t}</div>
              </div>
              <button onClick={()=>setRecommendations(null)} style={{background:"none",border:"none",color:MUTED,fontSize:"1.2rem",cursor:"pointer"}}>✕</button>
            </div>
            <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fill,minmax(160px,1fr))",gap:12}}>
              {recommendations.recs.map((rec,i)=>(
                <div key={i} onClick={()=>{setAddInput(rec.t);setRecommendations(null);}} style={{cursor:"pointer",borderRadius:6,overflow:"hidden",border:"1px solid rgba(255,255,255,0.07)",background:darkMode?"#0d0d18":"#f8f8f8",transition:"all 0.2s"}}
                  onMouseEnter={e=>{e.currentTarget.style.borderColor="rgba(245,197,24,0.4)";e.currentTarget.style.transform="translateY(-2px)";}}
                  onMouseLeave={e=>{e.currentTarget.style.borderColor="rgba(255,255,255,0.07)";e.currentTarget.style.transform="none";}}>
                  {rec.poster&&<img src={rec.poster} alt={rec.t} style={{width:"100%",aspectRatio:"2/3",objectFit:"cover",display:"block"}} />}
                  <div style={{padding:"8px 10px"}}>
                    <div style={{fontFamily:"'Georgia',serif",fontSize:"0.75rem",fontWeight:"bold",color:FG,lineHeight:1.3,marginBottom:3}}>{rec.t}</div>
                    {rec.year&&<div style={{fontFamily:"'Courier New',monospace",fontSize:"0.55rem",color:MUTED}}>{rec.year}</div>}
                  </div>
                </div>
              ))}
            </div>
            <div style={{marginTop:16,fontFamily:"'Courier New',monospace",fontSize:"0.6rem",color:MUTED,textAlign:"center",letterSpacing:"0.1em"}}>Click any film to add it to your queue</div>
          </div>
        </div>
      )}

      {/* ── NAVBAR ── */}
      <nav style={{
        position:"fixed", top:0, left:0, right:0, zIndex:10000,
        background:`linear-gradient(to bottom, ${darkMode?"rgba(10,10,13,0.98)":"rgba(244,240,232,0.98)"} 0%, ${darkMode?"rgba(10,10,13,0.85)":"rgba(244,240,232,0.85)"} 100%)`,
        backdropFilter:"blur(8px)", transition:"background 0.3s",
        borderBottom:`1px solid ${darkMode?"rgba(255,255,255,0.06)":"rgba(0,0,0,0.08)"}`,
      }}>
        {/* Main navbar row */}
        <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"0 16px",height:64}}>

          {/* Logo */}
          <div style={{display:"flex",flexDirection:"column",alignItems:"flex-start",gap:2,flexShrink:0}}>
            <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",width:"100%"}}>
              {Array.from({length:14},(_,i)=>(
                <div key={i} style={{width:4,height:4,borderRadius:"50%",flexShrink:0,background:"#f5c518",boxShadow:"0 0 4px #f5c518,0 0 8px #f5c518",margin:"0 2px",animation:`bulb 1.4s ease-in-out ${(i%3)*0.47}s infinite`}} />
              ))}
            </div>
            <div style={{display:"flex",alignItems:"center",gap:5}}>
              <span style={{display:"inline-block",fontSize:"1rem",animation:"wobble 3s ease-in-out infinite",lineHeight:1}}>🍿</span>
              <span style={{fontFamily:"'Impact','Arial Black',sans-serif",fontSize:"clamp(0.9rem,3vw,1.4rem)",fontWeight:900,color:"#f5c518",textShadow:"1px 1px 0 #7a620a",textTransform:"uppercase",letterSpacing:"-0.01em",lineHeight:1,whiteSpace:"nowrap"}}>The Watch Queue</span>
              <span style={{display:"inline-block",fontSize:"1rem",animation:"wobble 3s ease-in-out 1.5s infinite",lineHeight:1}}>🎬</span>
            </div>
          </div>

          {/* Desktop center filters — hidden on mobile */}
          <div style={{display:"flex",gap:6,alignItems:"center",position:"absolute",left:"50%",transform:"translateX(-50%)"}}>
            <style>{`@media(max-width:700px){.nav-filters{display:none!important}}`}</style>
            <div className="nav-filters" style={{display:"flex",gap:6}}>
              {[{k:"all",l:"All"},{k:"unwatched",l:"Unwatched"},{k:"watched",l:"Watched"}].map(f=>(
                <button key={f.k} onClick={()=>setFilter(f.k)} style={{fontFamily:"'Courier New',monospace",fontSize:"0.62rem",letterSpacing:"0.12em",textTransform:"uppercase",padding:"6px 14px",border:"1px solid",borderColor:filter===f.k?"#f5c518":"rgba(128,128,128,0.25)",background:filter===f.k?"rgba(245,197,24,0.1)":"transparent",color:filter===f.k?"#f5c518":MUTED,borderRadius:3,cursor:"pointer",transition:"all 0.15s"}}>{f.l}</button>
              ))}
            </div>
          </div>

          {/* Right side — desktop shows all, mobile shows minimal */}
          <div style={{display:"flex",alignItems:"center",gap:8,flexShrink:0}}>
            {/* Progress pill — always visible */}
            <div style={{display:"flex",alignItems:"center",gap:6,background:"rgba(128,128,128,0.1)",border:"1px solid rgba(128,128,128,0.15)",borderRadius:20,padding:"4px 10px"}}>
              <div style={{width:40,height:3,background:"rgba(128,128,128,0.2)",borderRadius:2,overflow:"hidden"}}>
                <div style={{height:"100%",background:"linear-gradient(90deg,#c0392b,#f5c518)",borderRadius:2,width:`${totalFilms?(watchedCount/totalFilms)*100:0}%`,transition:"width 0.5s"}} />
              </div>
              <span style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",color:"#f5c518",whiteSpace:"nowrap"}}>{watchedCount}/{totalFilms}</span>
            </div>

            {/* Dark mode — always visible */}
            <button onClick={()=>setDarkMode(d=>!d)}
              style={{background:"rgba(128,128,128,0.1)",border:"1px solid rgba(128,128,128,0.2)",borderRadius:3,padding:"5px 8px",cursor:"pointer",fontSize:"0.8rem",color:FG,flexShrink:0}}>
              {darkMode?"☀️":"🌙"}
            </button>

            {/* Desktop-only buttons */}
            <style>{`@media(max-width:700px){.nav-desktop{display:none!important}}`}</style>
            <div className="nav-desktop" style={{display:"flex",alignItems:"center",gap:8}}>
              <button onClick={copyLink} style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.1em",textTransform:"uppercase",background:"transparent",border:"1px solid rgba(230,57,70,0.35)",color:"#e63946",borderRadius:3,padding:"5px 12px",cursor:"pointer"}}>Share</button>
              <button onClick={()=>setShowWatchParty(true)} style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",letterSpacing:"0.1em",textTransform:"uppercase",background:"rgba(109,255,170,0.1)",border:"1px solid rgba(109,255,170,0.35)",color:"#6dffaa",borderRadius:3,padding:"5px 12px",cursor:"pointer",display:"flex",alignItems:"center",gap:4}}>🎉 Watch Party</button>
              <div style={{display:"flex",alignItems:"center",gap:6,padding:"4px 6px",borderRadius:4}}>
                <div style={{width:28,height:28,borderRadius:"50%",background:"linear-gradient(135deg,#793473,#f5c518)",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"'Impact',sans-serif",fontSize:"0.8rem",color:"#0a0a0d",fontWeight:900,flexShrink:0}}>{displayName.charAt(0).toUpperCase()}</div>
                <button onClick={signOut} style={{fontFamily:"'Courier New',monospace",fontSize:"0.55rem",letterSpacing:"0.1em",textTransform:"uppercase",background:"transparent",border:"1px solid rgba(128,128,128,0.2)",color:MUTED,borderRadius:3,padding:"3px 8px",cursor:"pointer"}}>Out</button>
              </div>
            </div>

            {/* Hamburger — mobile only */}
            <style>{`@media(min-width:701px){.nav-hamburger{display:none!important}}`}</style>
            <button className="nav-hamburger" onClick={()=>setMobileMenuOpen(m=>!m)}
              style={{background:"rgba(128,128,128,0.1)",border:"1px solid rgba(128,128,128,0.2)",borderRadius:4,padding:"6px 10px",cursor:"pointer",color:FG,fontSize:"1.1rem",lineHeight:1,flexShrink:0}}>
              {mobileMenuOpen?"✕":"☰"}
            </button>
          </div>
        </div>

        {/* Mobile menu drawer */}
        {mobileMenuOpen&&(
          <div style={{borderTop:`1px solid ${darkMode?"rgba(255,255,255,0.08)":"rgba(0,0,0,0.08)"}`,padding:"12px 16px 16px",display:"flex",flexDirection:"column",gap:12}}>
            {/* Filter tabs */}
            <div style={{display:"flex",gap:6}}>
              {[{k:"all",l:"All"},{k:"unwatched",l:"Unwatched"},{k:"watched",l:"Watched"}].map(f=>(
                <button key={f.k} onClick={()=>{setFilter(f.k);setMobileMenuOpen(false);}} style={{flex:1,fontFamily:"'Courier New',monospace",fontSize:"0.62rem",letterSpacing:"0.1em",textTransform:"uppercase",padding:"8px 6px",border:"1px solid",borderColor:filter===f.k?"#f5c518":"rgba(128,128,128,0.25)",background:filter===f.k?"rgba(245,197,24,0.1)":"transparent",color:filter===f.k?"#f5c518":MUTED,borderRadius:3,cursor:"pointer"}}>{f.l}</button>
              ))}
            </div>
            {/* Action row */}
            <div style={{display:"flex",gap:8,flexWrap:"wrap"}}>
              <button onClick={()=>{copyLink();setMobileMenuOpen(false);}} style={{fontFamily:"'Courier New',monospace",fontSize:"0.62rem",letterSpacing:"0.1em",textTransform:"uppercase",background:"transparent",border:"1px solid rgba(230,57,70,0.35)",color:"#e63946",borderRadius:3,padding:"8px 14px",cursor:"pointer",flex:1}}>Share</button>
              <button onClick={()=>{setShowWatchParty(true);setMobileMenuOpen(false);}} style={{fontFamily:"'Courier New',monospace",fontSize:"0.62rem",letterSpacing:"0.1em",textTransform:"uppercase",background:"rgba(109,255,170,0.1)",border:"1px solid rgba(109,255,170,0.35)",color:"#6dffaa",borderRadius:3,padding:"8px 14px",cursor:"pointer",flex:1}}>🎉 Watch Party</button>
              <button onClick={()=>{signOut();setMobileMenuOpen(false);}} style={{fontFamily:"'Courier New',monospace",fontSize:"0.62rem",letterSpacing:"0.1em",textTransform:"uppercase",background:"transparent",border:"1px solid rgba(128,128,128,0.2)",color:MUTED,borderRadius:3,padding:"8px 14px",cursor:"pointer",flex:1}}>Sign Out</button>
            </div>
            {/* User display */}
            <div style={{display:"flex",alignItems:"center",gap:8}}>
              <div style={{width:28,height:28,borderRadius:"50%",background:"linear-gradient(135deg,#793473,#f5c518)",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"'Impact',sans-serif",fontSize:"0.8rem",color:"#0a0a0d",fontWeight:900}}>{displayName.charAt(0).toUpperCase()}</div>
              <span style={{fontFamily:"'Courier New',monospace",fontSize:"0.62rem",color:MUTED}}>{displayName}</span>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Banner */}
      <div style={{paddingTop:64}}>
        <HeroBanner films={allFilms.filter(f=>!hiddenFilms[f.t])} watched={watched} onOpenFilm={f=>setSelectedFilm(f)} />
      </div>

      {/* All done banner */}
      {watchedCount>0&&watchedCount===totalFilms&&(
        <div style={{maxWidth:1100,margin:"16px auto 0",padding:"0 24px"}}>
          <div onClick={()=>setShowConfetti(true)} style={{textAlign:"center",fontFamily:"'Courier New',monospace",fontSize:"0.72rem",letterSpacing:"0.15em",color:"#f5c518",textTransform:"uppercase",padding:"12px",border:"1px solid rgba(245,197,24,0.3)",borderRadius:6,background:"rgba(245,197,24,0.05)",cursor:"pointer"}}>🏆 All watched! Certified cinema legend. Click to celebrate! 🏆</div>
        </div>
      )}

      <ActivityFeed feed={feed} onClickFriend={(uid,name)=>setFriendProfile({userId:uid,displayName:name})} />

      {/* ── TOOLBAR ── */}
      <div style={{maxWidth:1100,margin:"0 auto 14px",padding:"0 24px",display:"flex",flexDirection:"column",gap:10}}>

        {/* Row 1: Add + Reset */}
        <div style={{display:"flex",gap:10,alignItems:"center",flexWrap:"wrap"}}>
          <div style={{flex:1,minWidth:200,position:"relative"}}>
            <div style={{display:"flex",alignItems:"center",gap:8,border:`1px dashed ${addInput?"rgba(245,197,24,0.4)":"rgba(245,197,24,0.18)"}`,borderRadius:4,padding:"7px 12px",background:addInput?"rgba(245,197,24,0.04)":"transparent",transition:"all 0.2s"}}>
              <span style={{fontSize:"0.9rem",opacity:0.4}}>🔍</span>
              <input value={addInput} onChange={e=>setAddInput(e.target.value)} onKeyDown={e=>{if(e.key==="Escape"){setAddInput("");setSearchOpen(false);}}} placeholder="Add a movie to the queue..."
                style={{flex:1,background:"none",border:"none",outline:"none",color:FG,fontFamily:"'Georgia',serif",fontSize:"0.85rem",minWidth:0}} />
            </div>
            {searchOpen&&(
              <div style={{position:"absolute",left:0,right:0,top:"calc(100% + 4px)",background:darkMode?"#131318":"#fff",border:"1px solid rgba(245,197,24,0.25)",borderRadius:6,zIndex:500,boxShadow:"0 12px 40px rgba(0,0,0,0.8)",maxHeight:280,overflowY:"auto"}}>
                {searchLoading?(
                  <div style={{padding:14,textAlign:"center",fontFamily:"'Courier New',monospace",fontSize:"0.65rem",color:MUTED}}>
                    {[0,1,2].map(i=><span key={i} style={{display:"inline-block",width:4,height:4,borderRadius:"50%",background:"#f5c518",margin:"0 3px",animation:`dotpulse 1s ${i*0.15}s ease-in-out infinite`}} />)}
                  </div>
                ):searchResults.length===0?(
                  <div style={{padding:14,textAlign:"center",fontFamily:"'Courier New',monospace",fontSize:"0.65rem",color:MUTED}}>No results found</div>
                ):searchResults.map((page,i)=>(
                  <div key={i} onClick={()=>addFromSearch(page)} style={{display:"flex",alignItems:"center",gap:10,padding:"9px 14px",cursor:"pointer",borderBottom:`1px solid rgba(128,128,128,0.08)`,transition:"background 0.12s"}}
                    onMouseEnter={e=>e.currentTarget.style.background="rgba(245,197,24,0.06)"} onMouseLeave={e=>e.currentTarget.style.background="transparent"}>
                    <div style={{width:30,height:44,flexShrink:0,borderRadius:2,overflow:"hidden",background:"#0d0d18",display:"flex",alignItems:"center",justifyContent:"center",fontSize:11,color:MUTED}}>
                      {page.thumbnail?.source?<img src={page.thumbnail.source.replace(/\/\d+px-/,"/60px-")} alt="" style={{width:"100%",height:"100%",objectFit:"cover"}} />:"🎬"}
                    </div>
                    <div style={{flex:1,minWidth:0}}>
                      <div style={{fontFamily:"'Georgia',serif",fontSize:"0.8rem",color:FG,fontWeight:"bold",whiteSpace:"nowrap",overflow:"hidden",textOverflow:"ellipsis"}}>{page.title}</div>
                      <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.58rem",color:MUTED,marginTop:2,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{page.description||""}</div>
                    </div>
                    <span style={{color:"#f5c518",fontSize:"1.1rem",flexShrink:0}}>+</span>
                  </div>
                ))}
              </div>
            )}
          </div>
          <button onClick={resetAll} style={{fontFamily:"'Courier New',monospace",fontSize:"0.6rem",letterSpacing:"0.1em",textTransform:"uppercase",padding:"7px 14px",border:`1px solid rgba(128,128,128,0.2)`,background:"transparent",color:MUTED,borderRadius:3,cursor:"pointer",flexShrink:0}}>↺ Reset</button>
        </div>

        {/* Row 2: Queue search | Sort | Grid size | Surprise Me */}
        <div style={{display:"flex",gap:8,alignItems:"center",flexWrap:"wrap"}}>
          {/* Search within queue */}
          <div style={{display:"flex",alignItems:"center",gap:6,background:`rgba(128,128,128,0.07)`,border:`1px solid rgba(128,128,128,0.15)`,borderRadius:4,padding:"5px 10px",flex:1,minWidth:140}}>
            <span style={{opacity:0.4,fontSize:"0.75rem"}}>🔎</span>
            <input value={queueSearch} onChange={e=>setQueueSearch(e.target.value)} placeholder="Search your queue..."
              style={{background:"none",border:"none",outline:"none",color:FG,fontFamily:"'Courier New',monospace",fontSize:"0.65rem",minWidth:0,flex:1}} />
            {queueSearch&&<button onClick={()=>setQueueSearch("")} style={{background:"none",border:"none",color:MUTED,cursor:"pointer",fontSize:"0.7rem",padding:0}}>✕</button>}
          </div>

          {/* Sort */}
          <select value={sortBy} onChange={e=>setSortBy(e.target.value)}
            style={{fontFamily:"'Courier New',monospace",fontSize:"0.62rem",letterSpacing:"0.08em",padding:"6px 10px",border:`1px solid rgba(128,128,128,0.2)`,background:darkMode?"#111116":"#fff",color:FG,borderRadius:3,cursor:"pointer",outline:"none"}}>
            <option value="default">Sort: Default</option>
            <option value="rating">Sort: Rating</option>
            <option value="genre">Sort: Genre</option>
            <option value="added">Sort: Recently Added</option>
          </select>

          {/* Grid size */}
          <div style={{display:"flex",gap:3}}>
            {[{k:"sm",l:"▪"},{k:"md",l:"▪▪"},{k:"lg",l:"▪▪▪"}].map(g=>(
              <button key={g.k} onClick={()=>setGridSize(g.k)} title={`${g.k==="sm"?"Small":g.k==="md"?"Medium":"Large"} tiles`}
                style={{fontFamily:"monospace",fontSize:g.k==="sm"?"0.6rem":g.k==="md"?"0.75rem":"0.9rem",padding:"5px 9px",border:"1px solid",borderColor:gridSize===g.k?"#f5c518":"rgba(128,128,128,0.2)",background:gridSize===g.k?"rgba(245,197,24,0.1)":"transparent",color:gridSize===g.k?"#f5c518":MUTED,borderRadius:3,cursor:"pointer",lineHeight:1}}>
                {g.l}
              </button>
            ))}
          </div>

          {/* Surprise Me */}
          <button onClick={()=>{
            const unwatched=allFilms.filter(f=>!watched[f.t]&&!hiddenFilms[f.t]);
            if(!unwatched.length){showToast("You've watched everything! 🏆");return;}
            const pick=unwatched[Math.floor(Math.random()*unwatched.length)];
            setSelectedFilm(pick);
            showToast(`🎲 Surprise! Watching ${pick.t}`);
          }} style={{fontFamily:"'Courier New',monospace",fontSize:"0.62rem",letterSpacing:"0.1em",textTransform:"uppercase",padding:"6px 14px",border:"1px solid rgba(119,187,255,0.35)",background:"rgba(119,187,255,0.08)",color:"#77bbff",borderRadius:3,cursor:"pointer",whiteSpace:"nowrap",transition:"all 0.15s"}}
            onMouseEnter={e=>e.currentTarget.style.background="rgba(119,187,255,0.18)"} onMouseLeave={e=>e.currentTarget.style.background="rgba(119,187,255,0.08)"}>
            🎲 Surprise Me
          </button>
        </div>

        {/* Row 3: Tag filters */}
        <div style={{display:"flex",gap:6,flexWrap:"wrap",alignItems:"center"}}>
          <span style={{fontFamily:"'Courier New',monospace",fontSize:"0.55rem",color:MUTED,letterSpacing:"0.12em",textTransform:"uppercase",flexShrink:0}}>Genre:</span>
          <button onClick={()=>setTagFilter(null)}
            style={{fontFamily:"'Courier New',monospace",fontSize:"0.55rem",letterSpacing:"0.07em",padding:"2px 8px",borderRadius:10,border:`1px solid ${!tagFilter?"#f5c518":"rgba(128,128,128,0.2)"}`,background:!tagFilter?"rgba(245,197,24,0.12)":"transparent",color:!tagFilter?"#f5c518":MUTED,cursor:"pointer"}}>
            All
          </button>
          {allTags.map(tag=>{
            const s=TAG_STYLES[tag]||TAG_STYLES.crime;
            return(
              <button key={tag} onClick={()=>setTagFilter(tag===tagFilter?null:tag)}
                style={{fontFamily:"'Courier New',monospace",fontSize:"0.55rem",letterSpacing:"0.07em",padding:"2px 8px",borderRadius:10,border:`1px solid ${tagFilter===tag?s.color:s.border}`,background:tagFilter===tag?s.bg:"transparent",color:tagFilter===tag?s.color:MUTED,cursor:"pointer",textTransform:"capitalize",transition:"all 0.15s"}}>
                {tag}
              </button>
            );
          })}
        </div>

        {/* Drag hint */}
        <div style={{fontFamily:"'Courier New',monospace",fontSize:"0.55rem",color:MUTED,letterSpacing:"0.12em"}}>
          ⠿ drag to reorder &nbsp;·&nbsp; click to open &nbsp;·&nbsp; {filteredFilms.length} film{filteredFilms.length!==1?"s":""}
          {queueSearch&&` matching "${queueSearch}"`}
          {tagFilter&&` · ${tagFilter}`}
        </div>
      </div>

      {/* Poster grid */}
      <div style={{maxWidth:1100,margin:"0 auto",padding:"0 24px 80px"}}>
        <div style={{display:"grid",gridTemplateColumns:gridCols,gap:gridSize==="sm"?8:gridSize==="lg"?18:14}}>
          {filteredFilms.map((film,i)=>(
            <PosterTile key={film.t} film={film} index={i}
              isWatched={!!watched[film.t]}
              friendsWatched={friendsData[film.t]||[]}
              rating={ratings[film.t]||0}
              streamingLinks={streamingLinks[film.t]||{}}
              isDragging={dragIndex===i}
              onOpen={f=>setSelectedFilm(f)}
              onRemove={f=>removeFilm(f)}
              dragHandlers={{
                draggable:true,
                onDragStart:(e)=>{ e.dataTransfer.effectAllowed="move"; handleDragStart(i); },
                onDragEnter:()=>handleDragEnter(i),
                onDragOver:(e)=>{ e.preventDefault(); e.dataTransfer.dropEffect="move"; },
                onDragEnd:handleDragEnd,
                onDrop:(e)=>{ e.preventDefault(); handleDragEnd(); },
              }} />
          ))}
        </div>
        {filteredFilms.length===0&&(
          <div style={{textAlign:"center",padding:"60px 0",fontFamily:"'Courier New',monospace",fontSize:"0.7rem",color:MUTED,letterSpacing:"0.15em"}}>
            {queueSearch?`No films matching "${queueSearch}"`:tagFilter?`No ${tagFilter} films in your queue`:"No films in this filter."}
          </div>
        )}
      </div>

      {/* Modal */}
      {selectedFilm&&(
        <FilmModal film={selectedFilm}
          isWatched={!!watched[selectedFilm.t]}
          note={notes[selectedFilm.t]||""}
          rating={ratings[selectedFilm.t]||0}
          streamingLinks={streamingLinks[selectedFilm.t]||{}}
          friendsWatched={friendsData[selectedFilm.t]||[]}
          friendsRatings={friendsRatings[selectedFilm.t]||[]}
          isCustom={!!selectedFilm._custom && (!selectedFilm._addedBy || selectedFilm._addedBy === user.id)}
          currentUser={user}
          darkMode={darkMode}
          watchTogether={!!watchTogether[selectedFilm.t]}
          onWatchTogetherChange={v=>saveWatchTogether(selectedFilm.t,v)}
          sharedCustomUrl={sharedCustomUrls[selectedFilm.t]||""}
          onSharedCustomUrlChange={url=>saveSharedCustomUrl(selectedFilm.t,url)}
          onToggle={()=>{toggleWatched(selectedFilm);setSelectedFilm(null);}}
          onNoteChange={v=>saveNote(selectedFilm.t,v)}
          onRatingChange={v=>saveRating(selectedFilm.t,v,selectedFilm)}
          onStreamingChange={v=>saveStreamingLinks(selectedFilm.t,v,selectedFilm)}
          onDelete={()=>removeFilm(selectedFilm)}
          onClose={()=>setSelectedFilm(null)} />
      )}

      {/* Friend Profile */}
      {friendProfile&&(
        <FriendProfileModal userId={friendProfile.userId} displayName={friendProfile.displayName} darkMode={darkMode} onClose={()=>setFriendProfile(null)} />
      )}

      {/* Watch Party */}
      {showWatchParty&&(
        <WatchParty user={user} allFilms={allFilms.filter(f=>!hiddenFilms[f.t])} onClose={()=>setShowWatchParty(false)} />
      )}

      {/* Toast */}
      <div style={{position:"fixed",bottom:28,left:"50%",transform:`translateX(-50%) translateY(${toast?0:80}px)`,background:"#f5c518",color:"#0a0a0d",fontFamily:"'Courier New',monospace",fontSize:"0.75rem",fontWeight:"bold",letterSpacing:"0.12em",padding:"10px 24px",borderRadius:3,transition:"transform 0.35s cubic-bezier(0.34,1.56,0.64,1)",zIndex:99999,pointerEvents:"none",whiteSpace:"nowrap"}}>
        {toast}
      </div>

      <style>{`
        @keyframes bulb{0%,100%{opacity:1;box-shadow:0 0 5px #f5c518,0 0 10px #f5c518}50%{opacity:.2;box-shadow:none}}
        @keyframes wobble{0%,100%{transform:rotate(-5deg)}50%{transform:rotate(5deg)}}
        @keyframes dotpulse{0%,100%{opacity:.2;transform:scale(.7)}50%{opacity:1;transform:scale(1.2)}}
        @keyframes modalIn{from{opacity:0;transform:scale(0.94) translateY(10px)}to{opacity:1;transform:scale(1) translateY(0)}}
        *{margin:0;padding:0;box-sizing:border-box;}
        html{scroll-behavior:smooth;}
        ::-webkit-scrollbar{width:6px;}::-webkit-scrollbar-track{background:${BG};}::-webkit-scrollbar-thumb{background:#2a2a3a;border-radius:3px;}
        input::placeholder{color:${MUTED};}
        textarea::placeholder{color:${MUTED};font-style:italic;}
        [draggable]{-webkit-user-drag:element;}
        select option{background:${darkMode?"#111116":"#fff"};color:${FG};}
      `}</style>
    </div>
  );
}
