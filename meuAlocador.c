#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "meuAlocador.h"

void *topoInicialHeap;
void *topoFinalHeap;

// Executa syscall brk para obter o endereço do topo
// corrente da heap e o armazena em uma
// variável global, topoInicialHeap.
void iniciaAlocador(){
    topoInicialHeap = sbrk(0);
    printf("Endereço de inicio: %p\n", (void*)topoInicialHeap);
    topoFinalHeap = topoInicialHeap;
}

// Executa syscall brk para restaurar o valor
// original da heap contido em topoInicialHeap.
void finalizaAlocador(){
	brk(topoInicialHeap);
	topoFinalHeap = NULL;
}

 // indica que o bloco está livre.
int liberaMem(void* bloco){
    void *ptrAtual = bloco - 16;
    long int ocupado = *(long int*)ptrAtual;
    if (!ocupado) return 0;

    *(long int*)ptrAtual = 0;
    bloco = NULL;
    return 1;
}

// 1. Procura um bloco livre com tamanho maior ou
//    igual à num_bytes.
// 2. Se encontrar, indica que o bloco está
//    ocupado e retorna o endereço inicial do bloco;
// 3. Se não encontrar, abre espaço
//    para um novo bloco, indica que o bloco está
//    ocupado e retorna o endereço inicial do bloco.
void* alocaMem(int num_bytes){
    if (num_bytes <= 0)
        return NULL;
    
    void* ptrAtual = topoInicialHeap;
    
    printf("Endereço de ptrAtual1: %p\n", (void*)ptrAtual);
    printf("Endereço de final: %p\n", (void*)topoFinalHeap);

    void *noAuxiliar = NULL;
    long int tamNoAuxiliar = -1; // melhor caso

    while (ptrAtual < topoFinalHeap){
        long int ocupado = *(long int*)ptrAtual;
        long int tam = *(long int*)(ptrAtual + 8); // Lê o tamanho do bloco
        printf(" tam= %ld\n", tam);
        if (ocupado == 0 && tam >= num_bytes){
            if (noAuxiliar == NULL || tam > tamNoAuxiliar){
                printf(" tam= %ld\n", tam);
                noAuxiliar = ptrAtual;
                tamNoAuxiliar = tam;
            }
        } 
        // Vai procurar o proximo bloco mesmo que o verificado agora esteja ocupado
        // Para procurar um espaço melhor;
        ptrAtual += 16 + tam;
    }


    // Se nao encontrou bloco adequado espande a heap
    if (noAuxiliar == NULL && ptrAtual == topoFinalHeap){
        noAuxiliar = ptrAtual;
        // ate quando pode expandir, usando teto
        long int tamanhoNovoBloco = ((num_bytes + 31) / 32) * 32;

        long int auxTam = 16 + tamanhoNovoBloco;
        
        printf("aff %ld\n", auxTam);

        topoFinalHeap = sbrk(auxTam);
        topoFinalHeap = sbrk(0);

        // Ajusta cabeçalho para alocar bloco multiplo de 4096
        *(long int*)noAuxiliar = 0;
        *(long int*)(noAuxiliar + 8) = tamanhoNovoBloco;
        printf("Endereço de final: %p\n", (void*)topoFinalHeap);
    }

    printf("tam aux = %ld\n", *(long int*)(noAuxiliar + 8));
    *(long int*)noAuxiliar = 1;

    // Verificar se tem espaço nesse bloco encotrado para liberar o espaço que nao vai se usado
    if ((*(long int*)(noAuxiliar + 8) - num_bytes) > 16){
        // Posiciona o novo bloco e indentifica o cabeçalho dele
        void *ptrNovo = noAuxiliar + 16 + num_bytes;
        *(long int*)ptrNovo = 0;
        *(long int*)(ptrNovo + 8) = *(long int*)(noAuxiliar + 8) - num_bytes - 16;
        printf("novo %ld\n", *(long int*)(ptrNovo + 8));
        printf(" %ld\n", *(long int*)(ptrNovo));
        *(long int*)(noAuxiliar + 8) = num_bytes;
    }

    printf(" tam aux = %ld\n", *(long int*)(noAuxiliar + 8));
    return noAuxiliar + 16;
}

// imprime um mapa da memória da região da heap.
// Cada byte da parte gerencial do nó deve ser impresso
// com o caractere "#". O caractere usado para
// a impressão dos bytes do bloco de cada nó depende
// se o bloco estiver livre ou ocupado. Se estiver livre, imprime o
// caractere -". Se estiver ocupado, imprime o caractere "+".
void imprimeMapa(){
    void *ptrAtual = topoInicialHeap;
    
    while (ptrAtual < topoFinalHeap){
        printf ("################");
        long int ocupado = *(long int*)ptrAtual;
        long int tam = *(long int*)(ptrAtual + 8);

        if (ocupado == 0){
            for (long int i = 0; i < tam; i++)
                printf("-");
        }
        else{
            for (long int i = 0; i < tam; i++)
                printf("+");
        }
        
        ptrAtual += 16 + tam;
    }

    printf("\n");
}
