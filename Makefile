all:
	docker build -t crunchy-pg .
	docker tag -f crunchy-pg:latest crunchydata/crunchy-pg

