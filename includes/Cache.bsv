import GetPut::*;
import ClientServer::*;
import Memory::*;
import CacheTypes::*;
import WideMemInit::*;
import MemUtil::*;
import Vector::*;
import Fifo::*;
import Types::*;
import ProcTypes::*;
import MemTypes::*;


module mkTranslator(WideMem wideMem, Cache ifc);
    
   Fifo#(2, CacheWordSelect) cws <- mkCFFifo;
   method Action req(MemReq memreq);
      WideMemReq widememreq = toWideMemReq(memreq);
      CacheWordSelect wordsel = truncate( memreq.addr >> 2 );    		
      wideMem.req(widememreq);
      if (memreq.op == Ld) begin
	 cws.enq(wordsel);
	 $display("Cache Req D: op: Ld addr %x, wordsel = %x",memreq.addr, wordsel);
      end
      $display("Cache Req D: addr %x, wordsel = %x, op = ",memreq.addr, wordsel, fshow(memreq.op));
   endmethod
   
   method ActionValue#(MemResp) resp;
      CacheLine widememresp <- wideMem.resp;
      CacheWordSelect x = cws.first;
      cws.deq;
      $display("Cache Resp I: wordsel = %x",x);
      MemResp memresp = widememresp[x];
      $display("Cache response: wordsel = %x, inst:",x,showInst(memresp));
      return memresp; //where x is the word we want
   endmethod

endmodule


typedef enum {Ready,StartMiss, SendFillReq, WaitFillResp} CacheStatus deriving (Bits,Eq);

function CacheIndex getIndex(Addr addr) = truncate(addr>>6); //because it is bigger than example
function CacheWordSelect getOffset(Addr addr) = truncate(addr>>2);
function CacheTag getTag(Addr addr) = truncateLSB(addr);

//vectors of registers for cache
module mkCache(WideMem wideMem, Cache ifc);
    
   Fifo#(2, CacheWordSelect) cws <- mkCFFifo;

   Vector#(CacheRows, Reg#(CacheLine)) dataArray <- replicateM(mkRegU);
   Vector#(CacheRows, Reg#(Maybe#(CacheTag))) tagArray <- replicateM(mkReg(tagged Invalid));
   Vector#(CacheRows, Reg#(Bool)) dirtyArray <- replicateM(mkReg(False));

   Fifo#(2, Data) hitQ <- mkCFFifo;
   Reg#(MemReq) missReq <- mkRegU;
   Reg#(CacheStatus) mshr <- mkReg(Ready);

   //these are replace with wideMem methods
   //Fifo#(2, MemReq) memReqQ <- mkCFFifo;
   //Fifo#(2, CacheLine) memRespQ <- mkCFFifo;

   rule startMiss (mshr == StartMiss);
      $display("Start Miss: check if slot has dirty data");
      let idx = getIndex(missReq.addr);
      let tag = tagArray[idx];
      let dirty = dirtyArray[idx];
      let wordsel = getOffset(missReq.addr);    
      if (isValid(tag) && dirty) begin
	 let addr = {fromMaybe(?,tag), idx, 6'b0}; //piazza ask?
	 let data = dataArray[idx]; //this was not correct
	 Bit#(CacheLineWords) write_en = '1;
	 $display("data is dirty! writeback: addr = %x, data: = %x, st",addr,data);
	 //memReqQ.enq(MemReq{op: St, addr: addr, data: data}); //write back of dirty data
	 wideMem.req(WideMemReq{write_en: write_en, addr: addr, data: data});
      end
      mshr <= SendFillReq;
   endrule

   rule sendFillReq (mshr == SendFillReq);
      //memReqQ.enq(missReq); //request to memory
      $display("Send Fill Request to memory: req =",fshow(missReq));
      //wideMem.req(toWideMemReq(MemReq{op: Ld, addr: missReq.addr, data: missReq.data}));
      wideMem.req(toWideMemReq(MemReq{op: Ld, addr: missReq.addr, data: missReq.data}));
      mshr <= WaitFillResp;
   endrule

   //no response if got not a load ....
   rule waitFillResp(mshr == WaitFillResp);
      $display("Wait Fill Resp");
      let idx = getIndex(missReq.addr);
      let tag = getTag(missReq.addr);
      let wordsel = getOffset(missReq.addr);
      //let data = memRespQ.first;
      let data <- wideMem.resp;
      $display("this is data we got: %x",data);
      tagArray[idx] <= Valid(tag); //syntax?
      if (missReq.op == Ld) begin
	 $display("Got data, do load");
	 //let data <- wideMem.resp;
	 dirtyArray[idx] <= False;
	 dataArray[idx] <= data;
	 hitQ.enq(data[wordsel]);
      end
      else begin
	 $display("Got data, no load");
	 data[wordsel] = missReq.data;
	 dirtyArray[idx] <= True;
	 dataArray[idx] <= data;
	 $display("this is our new data, we didn't get data: %x",data);
      end
      $display("this is what our data array at indx = %x will be, line: %x",idx,dataArray[idx]);
      //memRespQ.deq;
      mshr <= Ready;
   endrule
   
   method Action req(MemReq memreq) if (mshr == Ready);
      let idx = getIndex(memreq.addr);
      let tag = getTag(memreq.addr);
      let wordsel = getOffset(memreq.addr);
      let currTag = tagArray[idx];
      $display("Tag = %x, currTag = %x",tag,currTag);
      let hit = isValid(currTag) ? fromMaybe(?,currTag) == tag : False;

      if (hit) begin
	 $display("Cache Hit!");
	 let x = dataArray[idx];
	 $display("wordsel: %x, data: ",wordsel,showInst(x[wordsel]));
	 if (memreq.op == Ld) begin
	    hitQ.enq(x[wordsel]);
	 end
	 else begin
	    x[wordsel] = memreq.data;
	    dataArray[idx] <= x;
	    dirtyArray[idx] <= True;
	 end
      end
	 else begin
	    $display("Cache Miss!: Start miss processing");
	    missReq <= memreq;
	    mshr <= StartMiss;
	 end	    
   endmethod
   
   method ActionValue#(MemResp) resp;
      hitQ.deq;    
      return hitQ.first;
   endmethod

endmodule
