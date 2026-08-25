# WAR=-Wall -Wextra
LIB=-lSDL2 -lm
TARGET=raycaster

all:
	gcc -ggdb $(WAR) $(LIB) -o $(TARGET) main.c 

clean:
	rm $(TARGET)

run:
	./$(TARGET)
