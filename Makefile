WAR=-Wall -Wextra
LIB=-lX11 -lXrandr -lm
TARGET=raycaster

all:
	gcc $(WAR) $(LIB) -o $(TARGET) main.c 

clean:
	rm $(TARGET)

run:
	./$(TARGET)
