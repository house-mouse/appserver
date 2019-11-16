
all: client-crt.pkcs12 server-crt.pem

rootCA-crt.pem rootCA-key.pem: certificate_authority.conf
	@echo "\nGenerating root certificate authority key and cert\n"
	openssl req -new -x509 -days 1024 -config certificate_authority.conf -keyout rootCA-key.pem -out rootCA-crt.pem

server-key.pem:
	@echo "\nGenerating server key\n"
	openssl genrsa -out server-key.pem 4096

server-csr.pem: server-key.pem server.conf
	@echo "\nGenerating server certificate signing request\n"
	openssl req -new -config server.conf -key server-key.pem -out server-csr.pem

server-crt.pem: server.conf server-csr.pem rootCA-crt.pem
	@echo "\nGenerating server certificate\n"
	openssl x509 -req -extfile server.conf -days 999 -passin "pass:password" -in server-csr.pem -CA rootCA-crt.pem -CAkey rootCA-key.pem -CAcreateserial -out server-crt.pem

client-key.pem:
	@echo "\nGenerating client key\n"
	openssl genrsa -out client-key.pem 4096

client-csr.pem: client.conf client-key.pem
	@echo "\nGenerating client certificate signing request\n"
	openssl req -new -config client.conf -key client-key.pem -out client-csr.pem

client-crt.pem: client-csr.pem rootCA-key.pem client.conf
	@echo "\nGenerating client certificate\n"
	openssl x509 -req -extfile client.conf -days 999 -passin "pass:password" -in client-csr.pem -CA rootCA-crt.pem -CAkey rootCA-key.pem -CAcreateserial -out client-crt.pem
	openssl verify -CAfile rootCA-crt.pem client-crt.pem


client-crt.pkcs12: client-key.pem client-crt.pem rootCA-crt.pem 
	openssl pkcs12 -export -passout pass:password -out client-crt.pkcs12 -inkey client-key.pem -in client-crt.pem -certfile rootCA-crt.pem 


clean:
	rm *.pem rootCA-crt.srl client-crt.pkcs12

