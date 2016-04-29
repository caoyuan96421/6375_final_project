
#include <iostream>
#include <unistd.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>
//#include <semaphore.h>

#include "bsv_scemi.h"
#include "SceMiHeaders.h"
#include "ResetXactor.h"

//this tb looks much more like audio pipeline than processor as we do NOT watch to load memory from PC

FILE* outpcm = NULL;

bool indone = false;
bool done = false;
long int putcount = 0;
long int gotcount = 0;

void out_cb(void* x, const BitT<4>& res)
{
  //if (gotcount < putcount) {
    char a = res.get(); 
    //std::cout << "Data Out:" << std::hex << static_cast<int>(a) << std::endl;
    fputc(a, outpcm);
    gotcount++;
    std::cout << "Got Count:" << gotcount << std::endl;
}

void count_cb(void* x, const BitT<64>& res){
    unsigned long long count = res;
    FILE *fp = fopen("cycle.txt", "w");
    fprintf(fp, "%lld\n",count);
    fclose(fp);
    
    std::cout << "Cycle count: " << count << std::endl;
}

void toFPGA(InportProxyT<BitT<4> >& fromhost)
{
  FILE* inpcm = fopen("in.pcm", "rb");
  if (inpcm == NULL) {
    std::cerr << "couldn't open in.pcm" << std::endl;
    return;
  }

  while (!indone) {
    char a = fgetc(inpcm);

    if (a == -1) { 
      indone = true;
      fclose(inpcm);
      inpcm = NULL;
      std::cout << "In Done!" << std::endl;
    } else {
      //std::cout << "Data In:" << std::hex << static_cast<int>(a) << std::endl;
      putcount ++;
      std::cout << "Put Count:" << putcount << std::endl;
      fromhost.sendMessage(BitT<4>(a));
    }
    sleep(0);
  }
}

int main(int argc, char* argv[])
{
    int sceMiVersion = SceMi::Version( SCEMI_VERSION_STRING );
    SceMiParameters params("scemi.params");
    SceMi *sceMi = SceMi::Init(sceMiVersion, &params);
    std::cout << "starting up..." << std::endl;
    // Initialize the SceMi ports
    InportProxyT<BitT<4> > inport("", "scemi_data_req_inport", sceMi);
    
    OutportProxyT<BitT<4> > outport("", "scemi_data_resp_outport", sceMi);
    outport.setCallBack(out_cb, NULL);
    
    InportProxyT<Bool> start ("", "scemi_start_inport",sceMi);
    
    OutportProxyT<BitT<64> > count("", "scemi_count_outport", sceMi);
    count.setCallBack(count_cb, NULL);
    
    ResetXactor reset("", "scemi", sceMi);
    ShutdownXactor shutdown("", "scemi_shutdown", sceMi);

    // Service SceMi requests
    SceMiServiceThread *scemi_service_thread = new SceMiServiceThread(sceMi);

    
    reset.reset();
    
    outpcm = fopen("out.pcm", "wb");
    if (outpcm == NULL) {
      std::cerr << "couldn't open out.pcm" << std::endl;
      return -1;
    }
    std::string user_input;
    //false is toFPGA, true is fromFPGA

    while (!done) {
      std::cout <<"Enter Mode (p for toFPGA, s for start, g for fromFPGA, q to Quit):" << std::endl;
      std::cin >> user_input;
      if (user_input == "q") {
	done = true;
      } else if (user_input == "p"){
	toFPGA(inport);
      } else if (user_input == "s"){
	start.sendMessage((BitT<1>)0);
      } else if (user_input == "g"){
      	//
      } else {
	std::cout << "Invalid Input!" << std::endl;
      }    
    }

    std::cout << "shutting down..." << std::endl;
    shutdown.blocking_send_finish();
    scemi_service_thread->stop();
    scemi_service_thread->join();
    SceMi::Shutdown(sceMi);
    std::cout << "finished" << std::endl;

    return 0;
}

