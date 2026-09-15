# Testes das regras (Firestore e Storage)

Cada caso aqui é uma porta que precisa continuar fechada (outra aluna
lendo fotos de evolução, cliente inflando XP) ou aberta (a coach lendo os
treinos da aluna). Rode sempre que mexer em `firestore.rules` ou
`storage.rules`, antes do deploy.

## Uma vez

Precisa de Node, do Firebase CLI e de Java (o emulador do Firestore é
Java). No Terminal, nesta pasta:

```bash
npm install
```

## Rodar

Nesta pasta:

```bash
npm test            # regras do Firestore (~70 casos)
npm run test:storage
```

Ele sobe o emulador, roda os casos e derruba tudo. No fim tem de aparecer
`TODOS OS CASOS PASSARAM`. Um `FALHOU ...` diz exatamente qual porta
abriu ou fechou sem querer.

Observação: o teste do Storage depende de o emulador conseguir consultar
o Firestore de dentro das regras (`firestore.get`). Em alguns ambientes
essa consulta cruzada não funciona no emulador e os casos "a coach baixa
a foto" e "a coach sobe imagem de prêmio" falham sem que a regra esteja
errada — em produção é a mesma consulta que já protege o upload de
documentos.
