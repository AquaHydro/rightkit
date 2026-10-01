import {createHash} from 'node:crypto';
import {chromium} from 'playwright';
import {readFile,mkdir,mkdtemp,rm} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {serve} from './server.mjs';
const args=process.argv.slice(2);
const option=(name,otherwise)=>{const i=args.indexOf(name);return i<0?otherwise:args[i+1];};
// FILM_PLAN selects another format (vertical/plan.json); default is the landscape film.
const planFile=process.env.FILM_PLAN||'plan.json';
const plan=JSON.parse(await readFile(planFile,'utf8'));
const output=option('--output','renders/technical-demo.mp4'), still=option('--still',null), audio=option('--audio',null);
const approvedSilent=!plan.demo && plan.audioRequired===false && typeof plan.audioExceptionReason==='string' && plan.audioExceptionReason.trim();
if(still===null && !audio && !approvedSilent && !args.includes('--silent-demo')) throw new Error('Provide --audio master.wav; silent technical tests require --silent-demo.');
if(still===null && !plan.demo && args.includes('--silent-demo')) throw new Error('Silent-demo is only for technical samples.');
if(still===null && !plan.demo && plan.audioRequired && plan.sfxRequired!==false) {
  const report=JSON.parse(await readFile(path.join(path.dirname(planFile),'evidence/audio-mix.json'),'utf8'));
  const digest=bytes=>createHash('sha256').update(bytes).digest('hex');
  if(report.planSha256!==digest(await readFile(planFile))) throw new Error('Audio mix is stale; rebuild for current plan.');
  if(!report.cues?.length) throw new Error('Music-only report: SFX cues missing.');
  if(!audio || digest(await readFile(audio))!==report.master.sha256) throw new Error('Use the verified BGM + SFX master.');
}
if(still!==null && (!Number.isFinite(Number(still)) || Number(still)<0 || Number(still)>=plan.duration)) throw new Error('Still time outside timeline');
await mkdir(path.dirname(output),{recursive:true});
const {server,url}=await serve();
let browser, frames;
try {
  browser=await chromium.launch({headless:true,...(process.env.FILM_CHANNEL?{channel:process.env.FILM_CHANNEL}:{})});
  const page=await browser.newPage({viewport:{width:plan.width,height:plan.height},deviceScaleFactor:1});
  const failures=[];
  page.on('pageerror',e=>failures.push(e.message));
  // Media elements routinely abort their own range requests; that is not a failure.
  page.on('requestfailed',r=>{if(r.resourceType()==='media'&&/ABORTED/.test(r.failure()?.errorText||''))return;failures.push(r.url());});
  page.on('response',r=>{if(r.status()>=400)failures.push(`${r.status()} ${r.url()}`);});
  await page.goto(url,{waitUntil:'networkidle'});
  await page.evaluate(async()=>{await document.fonts.ready;await Promise.all([...document.images].map(img=>img.decode()));
    // Footage must be decodable before the first seek.
    await Promise.all([...document.querySelectorAll('video')].map(v=>v.readyState>=2?0:new Promise((ok,no)=>{v.addEventListener('loadeddata',ok,{once:true});v.addEventListener('error',()=>no(new Error('video failed: '+v.src)),{once:true});v.load();})));});
  if(failures.length) throw new Error(failures.join('\n'));
  if(still!==null) {
    await page.evaluate(async t=>{window.seek(t);await window.ready();},Number(still));
    await page.screenshot({path:output});
  } else {
    frames=await mkdtemp(path.join(tmpdir(),'software-film-'));
    const total=Math.round(plan.duration*plan.fps);
    for(let f=0;f<total;f++) {
      await page.evaluate(async t=>{window.seek(t);await window.ready();},f/plan.fps);
      await page.screenshot({path:path.join(frames,`${String(f).padStart(6,'0')}.png`)});
    }
    if(failures.length) throw new Error(failures.join('\n'));
    const ff=['-v','error','-y','-framerate',String(plan.fps),'-i',path.join(frames,'%06d.png')];
    if(audio) ff.push('-i',audio,'-map','0:v:0','-map','1:a:0','-af','apad','-c:a','aac','-b:a','192k','-ar','48000');
    ff.push('-t',String(plan.duration),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',output);
    await new Promise((resolve,reject)=>{const p=spawn('ffmpeg',ff,{stdio:'inherit'});p.on('error',reject);p.on('close',code=>code===0?resolve():reject(new Error(`ffmpeg exited ${code}`)));});
  }
  console.log(output);
} finally {
  await browser?.close();
  await new Promise(resolve=>server.close(resolve));
  if(frames) await rm(frames,{recursive:true,force:true});
}
