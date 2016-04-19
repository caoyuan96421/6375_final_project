
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
  if (gotcount < putcount) {
    char a = res.get(); 
    std::cout << "Data Out:" << std::hex << static_cast<int>(a) << std::endl;
    fputc(a, outpcm);
    gotcount++;
    std::cout << "Got Count:" << gotcount << "Put Count:" << putcount << std::endl;
    if ((gotcount == putcount) && outpcm) {
      std::cout << "out done!" << std::endl;
      fclose(outpcm);
      outpcm = NULL;
      std::cout <<"Waiting for Mode (0 for toFPGA, 1 for fromFPGA, q to Quit):" << std::endl;
      return;
    }
  } else if (indone && outpcm) {
    fclose(outpcm);
    outpcm = NULL;
    done = true;
  }
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

    if (a == -1 ) { 
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
    OutportProxyT<BitT<4> > tohost("", "scemi_tohost_outport", sceMi);
    tohost.setCallBack(out_cb, NULL);
    InportProxyT<BitT<4> > fromhost("", "scemi_fromhost_inport", sceMi);
    InportProxyT<Bool> setmode ("", "scemi_setmode_inport",sceMi);
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
      std::cout <<"Enter Mode (0 for toFPGA, 1 for fromFPGA, q to Quit):" << std::endl;
      std::cin >> user_input;
      if (user_input == "q") {
	done = true;
      } else if (user_input == "0"){
	bool mode = false;
	setmode.sendMessage(mode);
	toFPGA(fromhost);
      } else if (user_input == "1"){
	bool mode = true;
	setmode.sendMessage(mode);
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

