# Nome do programa
PROG = avalia

# Arquivos de origem e objetos
ASM_SRC = malloc.s
C_SRC = avalia.c
OBJ = malloc.o avalia.o

# Compilador e flags
CC = gcc
ASM_FLAGS = -c -fno-pie
C_FLAGS = -c -fno-pie
LD_FLAGS = -no-pie

# Regra padrão
all: $(PROG)

# Regra para criar o executável
$(PROG): $(OBJ)
	$(CC) -o $@ $^ $(LD_FLAGS)

# Regras para os objetos
malloc.o: $(ASM_SRC)
	$(CC) $(ASM_FLAGS) -o $@ $<

avalia.o: $(C_SRC)
	$(CC) $(C_FLAGS) -o $@ $<

# Limpeza
clean:
	rm -f $(OBJ) $(PROG)
