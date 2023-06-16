ktpass.exe -princ HTTP/centos.example.com@EXAMPLE.COM ^
	-mapuser flask-svc@EXAMPLE.COM -pass Password1! ^
	-crypto ALL -ptype KRB5_NT_PRINCIPAL ^
	-out flask-svc.keytab