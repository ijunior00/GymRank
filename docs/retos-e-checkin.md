# Retos, prêmios e QR de check-in nas academias

Como a treinadora usa as duas ferramentas novas do painel, e o que
acontece por baixo. Tudo fica no painel da coach, na linha de botões
logo abaixo do cartão de convite: **Retos**, **Premios** e **QR de
check-in**.

## Retos

### Criar um reto

1. Painel → **Retos** → **Nuevo reto**.
2. Nome e (opcional) descrição.
3. **¿Qué cuenta?** Duas opções por enquanto: *Días entrenados* (cada
   dia com treino registrado ou sessão concluída soma 1) e *Check-ins*
   (cada check-in por QR soma 1). Kilos perdidos, masa muscular e km
   ficam de fora até existir a origem de dados; senão a aluna entra num
   reto que nunca avança.
4. Meta: um número inteiro (5 dias, 8 check-ins…).
5. Duração: *Una semana*, *Un mes* ou *Elegir fechas*.
6. XP ao completar: de 10 a 1000. Referência: um treino vale 50 XP e um
   check-in 20. O teto existe para um reto não valer mais que meses de
   treino no ranking nacional.
7. Prêmio (opcional): escolha um do catálogo ou crie ali mesmo.
8. **Publicar reto**. Aparece na hora na aba Retos das alunas da
   comunidade.

### O que acontece depois

- A aluna toca **Unirme al reto**. O progresso é calculado só pelo
  servidor, a partir de treinos e check-ins reais; ninguém digita
  progresso.
- Ao bater a meta: XP, prêmio (se houver e ainda tiver estoque),
  post automático no feed.
- A coach abre o reto e vê a lista de inscritas com a barra de progresso
  de cada uma, quem já completou e quando.
- **Terminar** encerra as inscrições e o progresso; dá para reativar.
  **Editar** muda nome, meta, datas, XP e prêmio.

### Prêmios

Painel → **Premios**. Cada prêmio tem nome, tipo (playera, sesión,
mensualidad…), quantidade e foto opcional. A quantidade baixa sozinha a
cada aluna que ganha; quando chega a zero, o reto continua dando XP mas
não entrega mais prêmio. Para repor, edite e suba o número.

## QR de check-in nas academias

### Cadastrar uma academia

1. Painel → **QR de check-in** → **Nueva academia**.
2. Nome e endereço.
3. **Usar mi ubicación actual**, estando na academia (ou digite
   latitude e longitude, que dá para copiar do Google Maps tocando e
   segurando no ponto). Se a precisão vier acima de 50 m, repita perto
   de uma janela.
4. Raio aceito: 150 m cobre o ginásio e o estacionamento. Suba se o GPS
   falhar lá dentro (prédios grandes, subsolo).
5. **Registrar academia** → **Ver e imprimir QR** → **Imprimir** (abre a
   impressão do navegador) ou **Descargar PDF**. Sai uma folha carta com
   a marca, o QR grande, o nome da academia e os três passos. Cole na
   recepção.

### Como a aluna faz check-in

- Com a câmera do celular: aponta para o QR, abre o link, o app pede a
  localização, ela confirma. Se não estiver logada, faz login e volta
  direto para a confirmação.
- Pelo app: **Check-in** na tela inicial, escaneia o QR.

O servidor confere: a assinatura do QR, se a academia está ativa, a
versão do QR, e a distância entre o celular e a academia (raio da
academia mais a imprecisão que o próprio celular declara, até 100 m).
Depois valem as regras de sempre: intervalo de 6 horas entre check-ins e
no máximo 2 check-ins com XP por dia. O check-in guarda em qual academia
foi e a que distância.

### Se um QR vazar

Alguém fotografou o QR e tenta usar de casa? Não passa pela distância.
Mesmo assim, se quiser trocar: **⋮ → Generar QR nuevo**. O papel antigo
deixa de valer na hora; imprima o novo e troque na recepção.
**Desactivar** pausa a academia sem apagar; **Eliminar** apaga.

### O que o GPS não resolve

Aplicativo de "localização falsa" engana o GPS. Para uma comunidade de
alunas, com o teto diário de XP, o intervalo de 6 horas e a coach vendo
a lista, é proteção suficiente. Quando o prêmio for valioso (um evento,
um torneio), use o QR rotativo: a tela da coach mostra um código que
muda a cada 30 segundos (function `issueCheckInToken`; a tela ainda não
foi construída, o servidor já sabe gerar).

## Por baixo do capô

| Peça | Onde |
|---|---|
| Formulário e limites do reto | `lib/features/challenges/…/challenge_form_screen.dart`, `challenge_form_rules.dart` |
| Regras dos retos e prêmios (mesmos limites) | `validChallenge` / `validReward` em `firestore.rules` |
| Contadores de inscritas e retos ativos | `functions/src/challenges/challengeCounters.ts` |
| Progresso, XP e prêmio ao completar | `functions/src/challenges/updateChallengeProgress.ts` |
| Academias (`coaches/{id}/locations`) | `lib/features/checkin/…/coach_locations_screen.dart`, regra `validLocation` |
| QR impresso: assinatura e link | `functions/src/checkin/locationQr.ts` (`issueLocationQr`) |
| Validação do check-in (dois tipos de QR, distância) | `functions/src/checkin/validateCheckIn.ts` |
| PDF para imprimir | `lib/features/checkin/presentation/location_qr_pdf.dart` |
| GPS do aparelho | `lib/features/checkin/data/geolocator_position_source.dart` |

O endereço do site vai impresso no QR (`PUBLIC_APP_URL` em
`functions/src/constants.ts`). Se um dia o domínio mudar, mantenha um
redirecionamento do antigo, senão os papéis nas academias param de
funcionar.
