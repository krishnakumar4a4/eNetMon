#include <iostream>
#include <sys/types.h>          /* See NOTES */
#include <sys/socket.h>
using namespace std;
int main()
{
  int sock;
  struct sockaddr sadr;
  char* recvd[1600];
  cout<<"Hello World"<<endl;
//check /etc/protocols file
//Below is for TCP packet
//sock = socket(AF_INET,SOCK_RAW,6);
//Below for icmp packet
  sock = socket(AF_INET,SOCK_RAW,1);

  cout<<"Socket:"<<sock<<endl;
/*
  if(bind(sock, &sadr, sizeof(sockaddr)) == -1)
        cout<<"bind Error"<<endl;
  else
        cout<<"bind success"<<endl;
*/
  recvfrom(sock,&recvd,1600,0,NULL,NULL);
  cout<<"Received:"<<recvd<<endl;
}
