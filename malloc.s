.section .data

    TOPO_INICIAL_HEAP: .quad 0
    FIM_HEAP: .quad 0

    STRING_GERENCIAL: .string "################"
    BYTE_LIVRE: .string "-"
    BYTE_OCUPADO: .string "+"
    BYTE_VAZIO: .string "\n"

.section .text

.globl iniciaAlocador
iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax           # codigo syscall brk
    movq $0, %rdi            # brk recebendo 0 retorna o valor atual do topo da heap
    syscall

    # salva endereco inicial da heap nas variaveis
    movq %rax, TOPO_INICIAL_HEAP
    movq %rax, FIM_HEAP

    popq %rbp
    ret

.globl finalizaAlocador
finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq TOPO_INICIAL_HEAP, %rdi        # carrega o topo da heap
    movq $12, %rax                      # codigo syscall brk
    syscall

    movq $0, FIM_HEAP                   # define fim_heap para null

    popq %rbp
    ret

.globl liberaMem
liberaMem:
    pushq %rbp
    movq %rsp, %rbp

    # Argumento da funcao eh o endereco do bloco em %rdi
    movq  %rdi, %rbx                    # ptrAtual = bloco
    subq $16, %rbx                      # ptrAtual -= 16
     
    cmpq $0, (%rbx)                     # verifica se o bloco ja esta desalocado
    je retorno_zero
    
    movq $0, (%rbx)                     # o bit de controle recebe 0
    movq $0, %rdi                       # bloco aponta para NULL
    movq $1, %rax
    popq %rbp
    ret

    retorno_zero:
        movq $0, %rax
        popq %rbp
        ret
    
    
.globl alocaMem
# %rdi tem o num_bytes
alocaMem:
    pushq %rbp
    movq %rsp, %rbp
    movq TOPO_INICIAL_HEAP, %rbx    # rbx(ptrAtual) <- Inicio da heap
    movq FIM_HEAP, %r10
    movq $0, %r12                   # o noAuxiliar = NULL
    movq $-1, %r11                  #tamNoAux = -1


    while_busca_melhor:
        cmpq %r10, %rbx             # verifica se rbx chegou ao fim da heap, pois eh necessario expandir
        jge fim_while               # se chegou, irá expandir

        movq (%rbx), %r13               # Saber se esta ocupado
        movq 8(%rbx), %r14              # Saber o tamanho do bloco
        
        cmpq $0, %r13                   #vefica se esta livre o bloco
        jne fim_if_externo
        cmpq %rdi, %r14                 # verifica se o tamanho do bloco é suficiente par o pedido
        jl  fim_if_externo 

        cmpq $0, %r12                   # verifica se o nó auxiliar tem valor nulo
        je condicao_verdadeira
        cmpq %r14, %r11                 # verifica se o tamanho do noAuxiliar é > que o tam atual
        jg condicao_verdadeira          
        jmp fim_if_externo              # sai do if

    condicao_verdadeira:
        movq %rbx, %r12                 # atualiza valor do no auxiliar
        movq %r14, %r11         
        jmp fim_if_externo              #para a linha que incrementa o while

    # Atualiza o valor de ptrAtual
    fim_if_externo:
        addq $16, %rbx
        addq %r14, %rbx
        jmp while_busca_melhor

    fim_while:
        cmpq $0, %r12                   # verifica se o nó auxiliar tem valor nulo
        jne fim_if_expandir
        cmpq %r10, %rbx
        jne fim_if_expandir
        movq %rbx, %r12                 # noAuxiliar <- ptrAtual;
        movq %rdi, %r15                 # tamanho do novo bloco recebe num_bytes para calcular quanto precisa ser expandido
        addq $4095, %r15
        shrq $12, %r15                  # divide a soma por 4096
        shlq $12, %r15                  # multiplica por 4096 para pegar o tamanho certo

        addq $16, %r15                  # para pegar o cabeçalho de informação
        movq %rdi, %r13                 # Salva o valor de num_bytes antes de alterar o reg
        movq $12, %rax                  # syscall para sbrk
        movq %r10, %rdi
        addq %r15, %rdi                 # soma o endereco do topo anterior com o crescimento
        syscall

        movq %rax, FIM_HEAP            # Pega o novo topo da heap
        movq %r13, %rdi                #restaurar parametro
        
        #atualiza cabeçalho
        movq $0, (%r12)
        subq $16, %r15                # Volta o valor original do novo bloco
        movq %r15, 8(%r12)             # salva valor do tamanho do bloco

    fim_if_expandir:
        movq $1, (%r12)                # No auxiliar recebera ocupado
        movq 8(%r12), %r13              # pega tamanho do bloco auxiliar
        subq %rdi, %r13                 # subtrai o valor de num_bytes do bloco alocado 
        cmpq $16, %r13                  # compara de esse valor é maior que 16
        jle fim_if_novo_no
        
        # novo = noAuxiliar + 16 + num_bytes
        movq %r12, %r13                
        addq $16, %r13
        addq %rdi, %r13                 

        # arruma cabeçalho do novo
        movq $0, (%r13)
        # tamNovo = tamNoAux - num_bytes - 16
        movq 8(%r12), %r14
        subq %rdi, %r14
        subq $16, %r14
        movq %r14, 8(%r13)
        movq %rdi, 8(%r12)

    fim_if_novo_no: 
        #retornar o endereço do bloco   
        addq $16, %r12
        movq %r12, %rax
        popq %rbp
        ret 

.globl imprimeMapa
imprimeMapa:
    pushq %rbp
    movq %rsp, %rbp
    movq TOPO_INICIAL_HEAP, %rbx                # rbx aponta para o inicio da heap
    movq FIM_HEAP, %r12

    loop_imprime:
        cmpq %rbx, %r12                            # verifica se chegou ao fim da heap
        jle fim_imprime                             # se chegou no fim, para de imprimir

        while_imprime:
        #imprimi informações gerenciais
        movq $1, %rax
        movq $1, %rdi
        movq $STRING_GERENCIAL, %rsi
        movq $16, %rdx
        syscall 

        movq (%rbx), %r13                           # Saber se esta ocupado
        movq 8(%rbx), %r14                          # Saber o tamanho do bloco

        cmpq $0, %r13                               #vefica se esta livre o bloco
        jne else

        movq $0, %r10
    for_1:
        cmpq %r14, %r10
        jge fora_for
        #imprimir caracter - pois esta livre
        movq $1, %rax
        movq $1, %rdi
        movq $BYTE_LIVRE, %rsi
        movq $1, %rdx
        syscall 

        addq $1, %r10
        jmp for_1
    else:
        movq $0, %r10
    for_2:
        cmpq %r14, %r10
        jge fora_for
        #imprimir caracter + pois esta ocupada
        movq $1, %rax
        movq $1, %rdi
        movq $BYTE_OCUPADO, %rsi
        movq $1, %rdx
        syscall 

        addq $1, %r10
        jmp for_2
    fora_for:
        addq $16, %rbx
        addq %r14, %rbx
        jmp loop_imprime
    fim_imprime:
        #imprimir caracter \n pois esta ocupada
        movq $1, %rax
        movq $1, %rdi
        movq $BYTE_VAZIO, %rsi
        movq $1, %rdx
        syscall

        popq %rbp
        ret

.section .note.GNU-stack,"",@progbits
