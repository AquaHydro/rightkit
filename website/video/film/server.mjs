import http from 'node:http';
import path from 'node:path';
import {readFile,realpath} from 'node:fs/promises';
const types={'.html':'text/html','.css':'text/css','.js':'text/javascript','.svg':'image/svg+xml','.png':'image/png','.webp':'image/webp','.jpg':'image/jpeg','.woff2':'font/woff2','.wav':'audio/wav','.mp3':'audio/mpeg','.mp4':'video/mp4'};
export async function serve(port=0) {
  const base=await realpath('dist');
  const server=http.createServer(async (req,res)=>{
    try {
      const name=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
      const file=await realpath(path.join(base,name==='/'?'index.html':name));
      if(!file.startsWith(base+path.sep)) {res.writeHead(403);res.end();return;}
      const body=await readFile(file),type=types[path.extname(file)]||'application/octet-stream';
      // Byte ranges let the browser seek inside video footage.
      const range=/bytes=(\d*)-(\d*)/.exec(req.headers.range||'');
      if(range){const a=range[1]?Number(range[1]):body.length-Number(range[2]),b=range[1]&&range[2]?Number(range[2]):body.length-1;
        res.writeHead(206,{'Content-Type':type,'Accept-Ranges':'bytes','Content-Range':`bytes ${a}-${b}/${body.length}`,'Content-Length':b-a+1});res.end(body.subarray(a,b+1));return;}
      res.writeHead(200,{'Content-Type':type,'Accept-Ranges':'bytes','Content-Length':body.length});res.end(body);
    } catch {res.writeHead(404);res.end('Not found');}
  });
  await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,'127.0.0.1',resolve);});
  return {server,url:`http://127.0.0.1:${server.address().port}`};
}
