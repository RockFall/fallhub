# Testar no celular sem desktop

O CI gera um APK debug e publica num release rolling. Você só precisa do GitHub no Android.

## 1. Bookmark (faça uma vez)

No Chrome do celular, salve:

**[Baixar fallhub-sideload.apk](https://github.com/RockFall/fallhub/releases/download/sideload-latest/fallhub-sideload.apk)**

Página do release: [sideload-latest](https://github.com/RockFall/fallhub/releases/tag/sideload-latest)

## 2. Instalar / atualizar

1. Espere o workflow **sideload_apk** ficar verde no PR ou em [Actions](https://github.com/RockFall/fallhub/actions/workflows/sideload_apk.yml).
2. Abra o link do APK.
3. Se o Android bloquear: **Permitir desta origem** (Chrome / Files) → Instalar.
4. Abra **Colônia → Configurações → Build de teste** e confira o commit.

Builds assinados com a mesma keystore de sideload **atualizam por cima** e mantêm os dados locais. Desinstalar apaga o banco.

## 3. Disparar um build novo

Qualquer um destes republica o mesmo link:

- Abrir ou atualizar um PR (o agente faz isso)
- Merge em `master`
- No celular: **GitHub → Actions → sideload_apk → Run workflow**

Se dois PRs rodarem perto, o último a terminar é o que o link entrega. Para forçar o branch atual: *Run workflow* nesse branch.

## 4. Primeira instalação

O Android pede permissão de “fontes desconhecidas” só na primeira vez por app de origem (Chrome, etc.).

Este APK é **debug de desenvolvimento**, não uma build de loja.
