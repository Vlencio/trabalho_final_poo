import asyncio
import httpx


BASE_URL = "http://localhost:8000"

GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"
BOLD = "\033[1m"


def log_step(n: int, title: str) -> None:
    print(f"\n{BOLD}{BLUE}[{n}] {title}{RESET}")


def log_ok(msg: str) -> None:
    print(f"  {GREEN}OK{RESET}  {msg}")


def log_info(msg: str) -> None:
    print(f"  {YELLOW}--{RESET}  {msg}")


def log_fail(msg: str) -> None:
    print(f"  {RED}FAIL{RESET}  {msg}")


class TestFailed(Exception):
    pass


def assert_status(resp: httpx.Response, expected: int = 200) -> None:
    if resp.status_code != expected:
        log_fail(f"esperado {expected}, recebeu {resp.status_code}")
        log_fail(f"body: {resp.text}")
        raise TestFailed()


async def main() -> None:
    # timeout alto porque o Claude leva alguns segundos para responder
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=60.0) as client:

        log_step(1, "Health check")
        resp = await client.get("/health")
        assert_status(resp)
        log_ok(f"resposta: {resp.json()}")

        log_step(2, "Criar usuario")
        resp = await client.post(
            "/users",
            json={"wa_id": "5534999990000", "nome": "Joao Teste"},
        )
        assert_status(resp)
        user = resp.json()
        user_id = user["id"]
        log_ok(f"usuario criado: id={user_id}, nome={user['nome']}")

        log_step(3, "Obter conversa ativa")
        resp = await client.post(f"/conversations/by-user/{user_id}")
        assert_status(resp)
        conv = resp.json()
        conv_id = conv["id"]
        log_ok(f"conversa: id={conv_id}, status={conv['status']}, score={conv['lead_score']}")

        log_step(4, "Simular conversa de qualificacao")
        user_messages = [
            "Oi, queria saber sobre as motos de voces",
            "Tenho interesse na Shineray XY 250",
            "Sou de Uberlandia, MG",
            "Quero financiar",
            "Pretendo comprar nos proximos 30 dias",
            "Tenho CNH categoria A sim",
            "Minha renda e de uns 5 mil por mes",
        ]

        for i, user_msg in enumerate(user_messages, 1):
            log_info(f"({i}/{len(user_messages)}) usuario: {user_msg}")
            resp = await client.post(
                f"/conversations/{conv_id}/messages",
                json={"content": user_msg},
            )
            assert_status(resp)
            data = resp.json()
            bot_text = data["bot_message"]["content"]
            conv_state = data["conversation"]
            log_info(f"      bot: {bot_text[:120]}{'...' if len(bot_text) > 120 else ''}")
            log_info(
                f"      score={conv_state['lead_score']}, "
                f"status={conv_state['status']}, "
                f"seller_id={conv_state['seller_id']}, "
                f"model_id={conv_state['model_id']}"
            )

        log_ok("conversa completa sem erros")

        log_step(5, "Verificar estado final da conversa")
        resp = await client.get(f"/conversations/{conv_id}")
        assert_status(resp)
        final = resp.json()
        log_ok(f"status final: {final['status']}")
        log_ok(f"score final: {final['lead_score']}")
        log_ok(f"vendedor atribuido: {final['seller_id']}")
        log_ok(f"modelo identificado: {final['model_id']}")

        if final["lead_score"] is None or final["lead_score"] == 0:
            log_fail("score nao foi atualizado! verifique o BotResponder")
            raise TestFailed()
        if final["status"] == "qualified":
            log_ok("conversa foi promovida para 'qualified' (handoff registrado)")

        log_step(6, "Metricas da conversa (function SQL)")
        resp = await client.get(f"/conversations/{conv_id}/metrics")
        assert_status(resp)
        metrics = resp.json()
        log_ok(f"total mensagens: {metrics['total_mensagens']}")
        log_ok(f"mensagens do cliente: {metrics['msgs_cliente']}")
        log_ok(f"mensagens do bot: {metrics['msgs_bot']}")
        log_ok(f"score final: {metrics['score_final']}")
        log_ok(f"status final: {metrics['status_final']}")

        log_step(7, "Listar conversas")
        resp = await client.get("/conversations")
        assert_status(resp)
        all_convs = resp.json()
        log_ok(f"total de conversas no banco: {len(all_convs)}")

        log_step(8, "Historico completo da conversa")
        resp = await client.get(f"/conversations/{conv_id}/messages")
        assert_status(resp)
        msgs = resp.json()["messages"]
        log_ok(f"total de mensagens registradas: {len(msgs)}")
        log_info("ultimas 4 mensagens:")
        for m in msgs[-4:]:
            preview = m["content"][:80] + ("..." if len(m["content"]) > 80 else "")
            print(f"        [{m['role']:>9}] {preview}")

        print(f"\n{GREEN}{BOLD}=== TODOS OS TESTES PASSARAM ==={RESET}\n")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except TestFailed:
        print(f"\n{RED}{BOLD}=== TESTE FALHOU ==={RESET}\n")
        exit(1)
    except httpx.ConnectError:
        print(f"\n{RED}{BOLD}Nao consegui conectar em {BASE_URL}.{RESET}")
        print(f"{RED}A API esta rodando? Verifique se voce subiu o uvicorn.{RESET}\n")
        exit(1)
