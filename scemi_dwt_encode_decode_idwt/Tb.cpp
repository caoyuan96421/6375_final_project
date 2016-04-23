
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

const int N=1024;
const int M=1024;
const int P=2;
const int L=3;

uint8_t in_data[N][M];
uint8_t out_data[N][M];

void runtest(InportProxyT<DWT_Line>& port){
	for(int j=0;j<M;j++){
		for(int i=0;i<N;i+=P){
			DWT_Line block;
			for(int k=0;k<P;k++){
				block[k] = (int8_t)(in_data[i+k][j] - 128);
			}
			port.sendMessage(block);
		}
	}
}

void flush_pipeline(InportProxyT<DWT_Line>& port){
	DWT_Line block;
	port.sendMessage(block);
}

int out_count = 0;
void out_cb(void* x, const DWT_Line& data){
	FILE *fout = (FILE *)x;
	int j=out_count / (N/P);
	int i=(out_count % (N/P))*P;
	for(int k=0;k<P;k++){
		out_data[i+k][j] = (uint8_t)data[k] + 128;
		fprintf(fout, "%u ", out_data[i+k][j]);
	}
	if(i+P == N){
		fprintf(fout, "\n");
		printf("Line %d received.\n", j);
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
			fscanf(fin,"%u", &in_data[i][j]);
		}
	}
	cout<<"Done."<<endl;
	
	fclose(fin);
}

int main(int argc, char* argv[])
{
	FILE *fout = fopen("out.txt", "w");
	
    int sceMiVersion = SceMi::Version( SCEMI_VERSION_STRING );
    SceMiParameters params("scemi.params");

    SceMi *sceMi = SceMi::Init(sceMiVersion, &params);
    // Initialize the SceMi inport
    InportProxyT<DWT_Line> data_inport ("", "scemi_datalink_req_inport", sceMi);
    
    // Initialize the SceMi outport
    OutportProxyT<DWT_Line> data_outport ("", "scemi_datalink_resp_outport", sceMi);
    data_outport.setCallBack(out_cb, fout);
    
    // Initialize the reset port.
    ResetXactor reset("", "scemi", sceMi);
    ShutdownXactor shutdown("", "scemi_shutdown", sceMi);
    
    // Service SceMi requests
    SceMiServiceThread *scemi_service_thread = new SceMiServiceThread (sceMi);

	// read data
	parse_file("in.txt");
	
    // Reset the dut.
    reset.reset();
    // Send in all the data.
    runtest(data_inport);

    while(!finished()){
    	flush_pipeline(data_inport);
    }

    cout << "shutting down..." << endl;
    fclose(fout);
    shutdown.blocking_send_finish();
    scemi_service_thread->stop();
    scemi_service_thread->join();
    SceMi::Shutdown(sceMi);
    cout << "finished" << endl;

    return 0;
}

