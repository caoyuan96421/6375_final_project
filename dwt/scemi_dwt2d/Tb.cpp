
#include <iostream>
#include <unistd.h>
#include <cmath>
#include <cstdlib>
#include <cctype>
#include <cstdio>
#include <fstream>
using namespace std;

#include "bsv_scemi.h"
#include "SceMiHeaders.h"
#include "ResetXactor.h"

const int N=2048;
const int M=2048;
const int P=8;
const int L=3;

float in_data[N][M];
float out_data[N][M];

float fromWSample(WSample f){
	int64_t g=(((uint64_t)(f.m_i) << f.m_f.getBitSize()) + (uint64_t)f.m_f);
	// sign extension
	uint64_t m=1ULL << (f.getBitSize() - 1);
	g=(g^m)-m;
	float x=(float)g/pow(2, f.m_f.getBitSize());
	return x;
}

WSample toWSample(float f){
	WSample w;
    w.m_i = (uint64_t) floor(f);
    w.m_f = (uint64_t)(pow(2, w.m_f.getBitSize()) * (f-floor(f)));
    return w;
}

void runtest(InportProxyT<DWT_Line>& port){
	for(int j=0;j<M;j++){
		for(int i=0;i<N;i+=P){
			DWT_Line block;
			//cout<<"Input "<<j<<" "<<i<<": ";
			for(int k=0;k<P;k++){
				float data = in_data[i+k][j];
				block[k] = toWSample(data);
			//	cout<<data<<" ";
			}
			//cout<<endl;
			port.sendMessage(block);
		}
	}
}

int out_count = 0;
bool passed = true;
const float releps = 0.01;
const float abseps = 0.2;
void out_cb(void* x, const DWT_Line& data){
	int j=out_count / (N/P);
	int i=(out_count % (N/P))*P;
	bool unitpassed=true;
	for(int k=0;k<P;k++){
		float x = fromWSample(data[k]);
		if(fabs((x-out_data[i+k][j])/out_data[i+k][j]) > releps && fabs(x-out_data[i+k][j]) > abseps)
			unitpassed = false;
	}
	if(!unitpassed){
		passed = false;
		cout<<"Output "<<out_count<<" ";
		for(int k=0;k<P;k++){
			cout<<fromWSample(data[k])<<" ";
		}
		cout<<" --> ";
		for(int k=0;k<P;k++){
			cout<<out_data[i+k][j]<<" ";
		}
		cout<<endl;
	}
	
	out_count ++;
	
}

bool finished(){
	return out_count >= N*M/P;
}

void parse_file(char *filename){
	cout<<"Parsing data file " << filename << "...";
	
	FILE *fin = fopen(filename, "r");
	
	if(fin == NULL){
		cerr<<"Error: "<<filename<<" cannot be opened"<<endl;
		exit(-1);
	}
	
	for(int j=0;j<M;j++){
		for(int i=0;i<N;i++){
			fscanf(fin,"%f", &in_data[i][j]);
		}
	}
	
	for(int j=0;j<M;j++){
		for(int i=0;i<N;i++){
			fscanf(fin, "%f", &out_data[i][j]);
		}
	}
	cout<<"Done."<<endl;
	
	fclose(fin);
}

float temp[N][M];
void interleave(int level){
	memcpy(temp, out_data, N*M*sizeof(float));
	int t=(1<<(level));
	for(int j=0; j<M/2; j+=t){
		for(int i=0; i<N/t; i++){
			temp[i][2*j] = out_data[i][j];
			temp[i][2*j+t] = out_data[i][j+M/2];
		}
	}
	memcpy(out_data, temp, N*M*sizeof(float));
}

int main(int argc, char* argv[])
{
	if(argc != 2){
		cerr<<"Error: must have one argument"<<endl;
		return 0;
	}
    int sceMiVersion = SceMi::Version( SCEMI_VERSION_STRING );
    SceMiParameters params("scemi.params");

    SceMi *sceMi = SceMi::Init(sceMiVersion, &params);
    // Initialize the SceMi inport
    InportProxyT<DWT_Line> data_inport ("", "scemi_datalink_req_inport", sceMi);
    
    // Initialize the SceMi outport
    OutportProxyT<DWT_Line> data_outport ("", "scemi_datalink_resp_outport", sceMi);
    data_outport.setCallBack(out_cb, NULL);
    
    // Initialize the reset port.
    ResetXactor reset("", "scemi", sceMi);
    ShutdownXactor shutdown("", "scemi_shutdown", sceMi);
    
    // Service SceMi requests
    SceMiServiceThread *scemi_service_thread = new SceMiServiceThread (sceMi);

	// read data
	parse_file(argv[1]);
	
	// interleave output to look the same as the module
	for(int i=0;i<L;i++)
		interleave(i);
		
	/*cout<<"Output should look like: "<<endl;
	for(int j=0;j<M;j++){
		for(int i=0;i<N;i+=P){
			for(int k=0;k<P;k++)
				cout<<out_data[i+k][j]<<" ";
			cout<<endl;
		}
	}*/
	
    // Reset the dut.
    reset.reset();
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

	if(passed)
		cout<<"PASSED"<<endl;
	else
		cout<<"FAILED"<<endl;
    return 0;
}

