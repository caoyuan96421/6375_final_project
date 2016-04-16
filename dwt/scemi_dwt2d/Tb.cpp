
#include <iostream>
#include <unistd.h>
#include <cmath>
#include <cstdlib>
#include <cctype>
#include <cstdio>
using namespace std;

#include "bsv_scemi.h"
#include "SceMiHeaders.h"
#include "ResetXactor.h"

const int N=8;
const int M=2048;
const int L=2048;

float fromWSample(WSample f){
	int g=(((uint32_t)(f.m_i) << f.m_f.getBitSize()) + (uint32_t)f.m_f);
	// sign extension
	unsigned int m=1 << (f.getBitSize() - 1);
	g=(g^m)-m;
	float x=(float)g/pow(2, f.m_f.getBitSize());
	return x;
}

WSample toWSample(float f){
	WSample w;
    w.m_i = (int) floor(f);
    w.m_f = (int)(pow(2, w.m_f.getBitSize()) * (f-floor(f)));
    return w;
}

void runtest(InportProxyT<DWT_Line>& port){
	for(int i=0;i<M*L/N;i++){
		DWT_Line msg;
//		cout<<"Input "<<i<<" ";
		for(int j=0;j<N;j++){
			float data = (float)((j+i*N+1)%256);
			msg[j] = toWSample(data);
//			cout<<data<<" ";
		}
//		cout<<endl;
		port.sendMessage(msg);
	}
}

int out_count = 0;
void out_cb(void* x, const DWT_Line& data){
	
//	cout<<"Output "<<out_count<<" ";
	for(int j=0;j<N;j++){
		float x = fromWSample(data[j]);
//		cout<<x<<" ";
	}
//	cout<<endl;
	printf("#");
	
	out_count ++;
}

bool finished(){
	return out_count >= M*L/N;
}

int main(int argc, char* argv[])
{
    int sceMiVersion = SceMi::Version( SCEMI_VERSION_STRING );
    SceMiParameters params("scemi.params");

    SceMi *sceMi = SceMi::Init(sceMiVersion, &params);
    // Initialize the SceMi inport
    InportProxyT<DWT_Line> data_inport ("", "scemi_datalink_req_inport", sceMi);
    
    InportProxyT<Tuple2_Bit_12_Bit_12> start_inport ("", "scemi_start_inport", sceMi);
    
    // Initialize the SceMi outport
    OutportProxyT<DWT_Line> data_outport ("", "scemi_datalink_resp_outport", sceMi);
    data_outport.setCallBack(out_cb, NULL);
    
    // Initialize the reset port.
    ResetXactor reset("", "scemi", sceMi);
    ShutdownXactor shutdown("", "scemi_shutdown", sceMi);
    
    // Service SceMi requests
    SceMiServiceThread *scemi_service_thread = new SceMiServiceThread (sceMi);

    // Reset the dut.
    reset.reset();
    // Start the module
    Tuple2_Bit_12_Bit_12 msg;
    msg.m_tpl_1 = L;
    msg.m_tpl_2 = M;
    start_inport.sendMessage(msg);
    
    // Send in all the data.
    runtest(data_inport);

    while(!finished()){
		sleep(0.1);
    }

    cout << "shutting down..." << endl;
    shutdown.blocking_send_finish();
    scemi_service_thread->stop();
    scemi_service_thread->join();
    SceMi::Shutdown(sceMi);
    cout << "finished" << endl;

    return 0;
}

