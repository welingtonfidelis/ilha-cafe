class_name Album
extends RefCounted
## Álbum de figurinhas da ilha (item 7 da lista de melhorias, 2026-11-10): cinco páginas que juntam o que a criança
## já viu e achou. Guardiões (cada um vencido), a turma dos esqueletos (cada tipo derrotado pelo menos uma vez), as
## figurinhas do esconde-esconde, os peixes da pescaria e os bilhetes espalhados pela ilha. As imagens dos guardiões,
## da turma e dos peixes saem de tools/gerar_figurinhas.gd (assets/ui/figurinhas/); os bilhetes são desenhados.
## Aqui ficam só os dados e quem já foi achado; a tela é o PainelAlbum e o bilhete no chão é o Bilhete.

const FIGURAS := "res://assets/ui/figurinhas/%s.png"

## Guardião de cada região (a chave é a região da Story).
const GUARDIOES := {
	"oeste": {"guardiao": "ossao", "nome": "Ossão", "texto": "O guardião da Lanterna Oeste, com o escudo e o martelinho. Hoje só pensa em hambúrguer."},
	"leste": {"guardiao": "mira_torta", "nome": "Mira-Torta", "texto": "A guardiã da Lanterna Leste. Errou tanto que virou a melhor da barraca de tiro."},
	"clareira": {"guardiao": "torre", "nome": "Torre de Ossinhos", "texto": "Quatro Ossinhos, um em cima do outro. Quem fica embaixo sempre reclama."},
	"ventos": {"guardiao": "minionzao", "nome": "Minionzão", "texto": "O maior Ossinho da ilha. Fica tonto rodando e mais tonto ainda dançando."},
	"vila": {"guardiao": "planta", "nome": "Guerreiro Planta", "texto": "O guardião da mata, do Bosque das Copas. Amigo de quem cuida das plantas."},
	"cemiterio": {"guardiao": "mestre", "nome": "Mestre Ossinho", "texto": "O chefe dos esqueletos. Só queria um convite para a festa."},
}
## A turma: cada tipo de esqueleto e de amigo do Morro que aparece nas ondas e pela ilha.
const TURMA := [
	{"id": "Skeleton_Minion", "nome": "Ossinho", "texto": "O menor da turma. Corre atrás de você com um pirulito na mão."},
	{"id": "Skeleton_Warrior", "nome": "Guerreiro", "texto": "Tem escudo de tampa de panela. Pela frente, o tiro não passa."},
	{"id": "Skeleton_Rogue", "nome": "Arqueiro", "texto": "Atira flechinha de ventosa de longe. Ande de lado que ela erra."},
	{"id": "Skeleton_Mage", "nome": "Mago", "texto": "Joga bolhas mágicas que estouram em confete."},
	{"id": "Skeleton_Pistoleiro", "nome": "Pistoleiro", "texto": "Tem um blaster de quindim e corre de lado para fugir da mira."},
	{"id": "Skeleton_Golem", "nome": "Golem de Ossos", "texto": "Grandão e pesado. Quando bate no chão, a terra treme."},
	{"id": "Lobinho", "nome": "Lobinho", "texto": "Uiva, pula e quer brincar de pega-pega o tempo todo."},
	{"id": "Conde", "nome": "Conde", "texto": "Some e aparece de surpresa. Prometeu nunca mais assustar ninguém."},
	{"id": "Grandalhao", "nome": "Grandalhão", "texto": "Tem um escudo na frente e outro na cabeça. Mire nas costas!"},
	{"id": "GolemDeGelo", "nome": "Golem de Gelo", "texto": "Feito de gelo do Pico Gelado. Gosta de sorvete, claro."},
	{"id": "Dourado", "nome": "Esqueleto Dourado", "texto": "Raro! Aparece de vez em quando, foge correndo e solta um monte de moedas."},
]
## Os bilhetes pela ilha: onde ficam (perto daqui, onde tiver chão livre), quem escreveu, o texto e a figura.
const BILHETES := [
	{"id": "ponte", "onde": Vector3(6, 0, -140), "de": "Minionzão", "icone": "ponte",
		"texto": "Eu fiquei com medo da ponte balançar. Ela não balança. Mas eu fiquei com medo mesmo assim."},
	{"id": "sitio", "onde": Vector3(-103, 0, -2), "de": "Lobinho", "icone": "casa",
		"texto": "Os cavalos do sítio correram de mim. Eu só queria brincar de pega-pega!"},
	{"id": "farol", "onde": Vector3(144, 0, 144), "de": "Vovô da praça", "icone": "binoculo",
		"texto": "Quando eu era pequeno, o farol piscava a noite inteira. Hoje ele pisca só para você."},
	{"id": "clareira", "onde": Vector3(50, 0, -170), "de": "Torre de Ossinhos", "icone": "torre",
		"texto": "A gente subia um em cima do outro só para ver a festa lá de longe."},
	{"id": "bosque", "onde": Vector3(115, 0, -141), "de": "Guerreiro Planta", "icone": "planta",
		"texto": "Regue as plantinhas. Elas também gostam de festa."},
	{"id": "ventos", "onde": Vector3(-62, 0, -150), "de": "Mira-Torta", "icone": "mira_torta",
		"texto": "Aqui em cima venta tanto que as minhas flechinhas voltavam para mim!"},
	{"id": "pista", "onde": Vector3(98, 0, -6), "de": "Conde", "icone": "kart",
		"texto": "Andei de kart sem frear. Agora eu sei para que serve o freio."},
	{"id": "morro", "onde": Vector3(14, 0, 92), "de": "Mestre Ossinho", "icone": "mestre",
		"texto": "Lá em cima do Morro não tem nada de festa. Nadinha. Pode ir embora. Hum... tem bolo?"},
]
const MOEDAS_BILHETE := 5

## As páginas, na ordem das abas: chave, nome, ícone e cor.
const PAGINAS := [
	["guardioes", "Guardiões", "mestre"],
	["turma", "Turma", "esqueleto"],
	["esconde", "Esconde-esconde", "esconde"],
	["peixes", "Peixes", "peixe"],
	["bilhetes", "Bilhetes", "bilhete"],
]


## As figurinhas de uma página: [{id, nome, texto, imagem (Texture2D ou nulo), icone, achada}].
static func figurinhas(pagina: String, game: Node) -> Array:
	var story: Story = game.story
	var out := []
	match pagina:
		"guardioes":
			for id: String in GUARDIOES:
				var g: Dictionary = GUARDIOES[id]
				var d: Defense = story.defenses.get(id)
				out.append({"id": id, "nome": g.nome, "texto": g.texto, "imagem": _imagem("guardiao_" + id),
					"achada": d != null and d.state == Defense.State.VENCIDA})
		"turma":
			for t: Dictionary in TURMA:
				out.append({"id": t.id, "nome": t.nome, "texto": t.texto, "imagem": _imagem("tipo_" + t.id),
					"achada": story.derrotados.has(t.id)})
		"esconde":
			var tem: Array = game.esconde.figurinhas if game.esconde else []
			for f: Dictionary in EscondeEsconde.FIGURINHAS:
				out.append({"id": f.id, "nome": f.nome, "texto": "Achado no esconde-esconde. Ele se esconde melhor que você!",
					"imagem": _imagem("tipo_" + f.id), "achada": f.id in tem, "brilho": true})
		"peixes":
			var pegos: Dictionary = game.pescaria.pegos if game.pescaria else {}
			for p: Dictionary in Pescaria.PEIXES:
				var n := int(pegos.get(p.id, 0))
				out.append({"id": p.id, "nome": p.nome, "texto": "Pescado na ponta do cais (%d vez%s). %s" % [n, "" if n == 1 else "es",
					["", "Fácil de achar.", "Aparece de vez em quando.", "Raro!"][p.raro]], "imagem": _imagem("peixe_" + p.id), "achada": n > 0})
		"bilhetes":
			for i in BILHETES.size():
				var b: Dictionary = BILHETES[i]
				out.append({"id": b.id, "nome": "Bilhete %d" % (i + 1), "texto": "%s — %s" % [b.texto, b.de], "imagem": null,
					"icone": "bilhete", "achada": b.id in story.bilhetes})
	return out


## Quantas já achou e quantas tem, numa página ou no álbum todo (pagina vazia).
static func contagem(game: Node, pagina := "") -> Vector2i:
	var conta := Vector2i.ZERO
	for p in PAGINAS:
		if pagina != "" and p[0] != pagina:
			continue
		for f: Dictionary in figurinhas(p[0], game):
			conta.y += 1
			if f.achada:
				conta.x += 1
	return conta


static func _imagem(nome: String) -> Texture2D:
	var caminho := FIGURAS % nome
	return load(caminho) if ResourceLoader.exists(caminho) else null


static func bilhete(id: String) -> Dictionary:
	for b: Dictionary in BILHETES:
		if b.id == id:
			return b
	return {}
