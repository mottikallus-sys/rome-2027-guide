#!/usr/bin/env python3
"""Pull a short, attributed Rome news briefing from public RSS sources.
Run daily by GitHub Actions. No API key required and no article bodies republished.
"""
import datetime as dt
import email.utils
import html
import json
import re
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse

HERE = Path(__file__).resolve().parent.parent
DEST = HERE / "rome-news.json"
SOURCES = [
    ("RomaToday", "https://www.romatoday.it/rss", "general"),
    ("Wanted in Rome", "https://www.wantedinrome.com/news?format=feed", "general"),
    ("Romeing", "https://www.romeing.it/feed/", "events"),
    ("ATAC", "https://www.atac.roma.it/rss.aspx", "transport"),
]
TOPICS = {
    "transport": ("metro", "bus", "tram", "treno", "train", "strike", "scioper", "airport", "aeroporto", "fiumicino", "ciampino", "traffico", "traffic", "chiusura", "closed", "closure", "atac", "trasport", "transport", "viabilit"),
    "events": ("mostra", "exhibition", "concerto", "concert", "festival", "evento", "event", "muse", "teatro", "theater", "show", "mercatino", "natale", "christmas"),
    "alerts": ("allerta", "alert", "meteo", "weather", "incend", "flood", "emergenz", "protest", "sicurez", "warning"),
}
def clean(value):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]*>", " ", value or ""))).strip()

def first(item, paths):
    for path in paths:
        obj = item.find(path)
        if obj is not None and obj.text:
            return clean(obj.text)
    return ""

def parse_date(value):
    if not value:
        return None
    try:
        result = email.utils.parsedate_to_datetime(value)
        if result:
            return result.astimezone(dt.timezone.utc) if result.tzinfo else result.replace(tzinfo=dt.timezone.utc)
    except (TypeError, ValueError, OverflowError):
        pass
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(dt.timezone.utc)
    except ValueError:
        return None

def read_source(source, address, default):
    req = urllib.request.Request(address, headers={"User-Agent": "RomeTripNews/1.0 (public RSS reader)", "Accept": "application/rss+xml, application/atom+xml, application/xml, text/xml, */*"})
    with urllib.request.urlopen(req, timeout=18) as res:
        body = res.read(1_500_000)
    root = ET.fromstring(body)
    candidates = root.findall("./channel/item")
    if not candidates:
        candidates = root.findall(".//{http://www.w3.org/2005/Atom}entry")
    today = dt.datetime.now(dt.timezone.utc)
    output = []
    for item in candidates[:80]:
        title = first(item, ["title", "{http://www.w3.org/2005/Atom}title"])
        link = first(item, ["link"])
        if not link:
            l = item.find("{http://www.w3.org/2005/Atom}link")
            link = l.attrib.get("href", "") if l is not None else ""
        date = parse_date(first(item, ["pubDate", "published", "updated", "{http://www.w3.org/2005/Atom}published", "{http://www.w3.org/2005/Atom}updated", "{http://purl.org/dc/elements/1.1/}date"]))
        if not title or not link.startswith("https://") or not date:
            continue
        host = (urlparse(link).hostname or "").lower()
        if not (host == urlparse(address).hostname or host.endswith("." + (urlparse(address).hostname or ""))):
            continue
        if not (today - dt.timedelta(days=8) <= date <= today + dt.timedelta(hours=3)):
            continue
        full = title.lower()
        topic = next((category for category, words in TOPICS.items() if any(w in full for w in words)), default)
        output.append({"title": title[:180], "url": link, "source": source, "published": date.isoformat().replace("+00:00", "Z"), "category": topic})
    return output

def main():
    now = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    entries, status = [], {}
    for name, url, topic in SOURCES:
        try:
            feed = read_source(name, url, topic)
            entries += feed
            status[name] = len(feed)
            print(f"{name}: {len(feed)}")
        except Exception as e:
            status[name] = "unavailable"
            print(f"{name}: unavailable ({type(e).__name__})")
    seen, results = set(), []
    for entry in sorted(entries, key=lambda x: x["published"], reverse=True):
        key = entry["url"].split("?")[0].rstrip("/")
        if key in seen:
            continue
        seen.add(key)
        results.append(entry)
    output = {"updated": now, "automatic": True, "articles": results[:32], "sources": status}
    if not results and DEST.exists():
        prior = json.loads(DEST.read_text(encoding="utf-8"))
        output = prior
        output["attempted"] = now
        output["sources"] = status
        print("No feeds reachable; preserving cached news with prior timestamp.")
    DEST.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Saved", len(output.get("articles", [])), "articles.")

if __name__ == "__main__":
    main()
