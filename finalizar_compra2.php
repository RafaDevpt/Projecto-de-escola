<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>EPALTE Online - Finalizar compra</title>
<link href="../default.css" rel="stylesheet" type="text/css" media="all" />
<link href="../fonts.css" rel="stylesheet" type="text/css" media="all" />
<!--[if IE 6]>
<link href="../default_ie6.css" rel="stylesheet" type="text/css" />
<![endif]-->
<style type="text/css">
.auto-style1 {
	width: 1200px;
	margin-right: auto;
	margin-top: 0px;
	margin-bottom: 0px;
}
</style>
</head>
<body style="background-image:url('../images/madeira.jpg')">
<div id="wrapper">
	<div id="header-wrapper">
		<div id="header" class="container" style="left: 0px; top: 0px">
			<div id="logo">
				<h1><a href="#">EPALTE Online</a></h1>
				<p>Design by: DispenserStock Team</p>
			</div>
		</div>
	</div>
	<div id="menu-wrapper">
		<div id="menu" class="container">
			<ul>
				<li><a href="index.php">Homepage</a></li>
				<li><a href="Sobre.php">Sobre</a></li>
				<li><a href="Produtos.php">Produtos</a></li>
				<li><a href="Politica de Privacidade.php">Politica de Privacidade</a></li>
				<li><a href="Contacto.php">Contacto</a></li>
		     	<li><a href="Carrinho.php">Carrinho</a></li>
				<li class="current_page_item"><a href="login.php">Login</a></li>
			</ul>
		</div>
		<!-- end #menu --> 
	</div>
	<div id="banner"></div>
			<div class="title">
				<h2 align="center">Finalizar Compra</h2>
				<p>
<?php
//inciar sessao
session_start();
//ligacao a base de dados
include('ligacao_db.php');
//preparar sessao de compra
$sessao = session_id();
//capturar identificaçao do cliente
$id_cliente = $_SESSION['id_cliente'];
$sql_cliente = 'SELECT * FROM clientes WHERE id_cliente='.$id_cliente;
$consulta1 = mysql_query($sql_cliente);
$mostrar = mysql_fetch_array($consulta1);
extract ($mostrar);
//apresentar tabela com os dados do utilizador
echo "<table width='800px' border='1' align='center'>";
echo "<tr><td><strong>Passo 2 - Resumo da Compra</strong></td></tr>";
?>
<tr>
<td>
<table>
<tr><td>Primeiro Nome: <?php echo $primeiro_nome; ?></td>
</tr>
<tr><td>Ultimo nome: <?php echo $apelido; ?></td>
</tr>
<tr><td>Rua/lugar: <?php echo $endereco; ?></td>
</tr>
<tr><td>Localidade: <?php echo $localidade; ?></td>
</tr>
<tr><td>Código-Postal: <?php echo $codigo_postal; ?></td>
</tr>
<tr><td>Email: <?php echo $email; ?></td>
</tr>
</table>
<?php
//pesquisar artigos no carrinho
$sql_carrinho = 'SELECT * FROM compra_temporaria temp JOIN artigos prod ON temp.id_artigo = prod.id_artigo WHERE sessao= "'. $sessao.'"ORDER BY temp.id_artigo ASC';
$consulta2 = mysql_query($sql_carrinho);
$resultado = mysql_num_rows($consulta2);
//apresentar os artigos adicionados ao carrinho
if ($resultado > 0) {
$total = 0;
echo "<table width='800' border='1' align='center'>";
echo "<th>Imagem artigo</th><th>Detalhe Artigo</th><th>Quantidade</th><th>Preço unitario</th><th>Total a pagar</th>";
while ($mostrar = mysql_fetch_array($consulta2)) {
extract ($mostrar);
echo "<tr><td align='center' width='100' height='100' valign='middle'><img src='$pasta_imagens".$imagem_artigo."' border='0'></a>";
echo "<td align='center'>".$descricao_artigo."</td></a>";
echo "<td align='center'>".$quantidade."</td>";
echo "<td align='center'>EUR".$preco_artigo."</td>";
//calcular subtotal
$sub_total = number_format($preco_artigo * quantidade, 2);
echo "<td align='center'>EUR".$sub_total."</td>";
//calcular valor total de compras
$total = $total + $preco_artigo * $quantidade;
}
echo "<tr><td align='right' colspan='5'>O valor total a pagar é de: <strong>EUR".number_format($total,2)."</strong></td></tr>";
}
//registar nova compra na base de dados
$sql_regista_compra = "INSERT INTO compra_confirmada(data_compra, id_cliente, total_pagar) VALUES (NOW(),'".$id_cliente."','".$total."')";
$consulta3 = mysql_query($sql_regista_compra);
$id_compra = mysql_insert_id();
$sql_regista_detalhes_compra = 'INSERT INTO detalhes_compra(id_compra, quantidade_compra, id_artigo) SELECT '.$id_compra.', quantidade, id_artigo FROM compra_temporaria WHERE sessao = "'.$sessao . '"';
$consulta4 = mysql_query($sql_regista_detalhes_compra);
//eliminar dados temporarios da compra
$sql_elimina_temp = 'DELETE FROM compra_temporaria WHERE sessao="'.$sessao.'"';
$consulta5 = mysql_query($sql_eliminia_temp);
echo "<td colspan='5'>A sua compra foi realizada com sucesso e ficou registada com o numero: ".$id_compra;
echo "<p>Sera enviada uma copia dos detalhes da compra para o seu e-mail! </p>";
session_unset();
session_destroy();
echo "<p><a href='index.php'>Clique para voltar à pagina inicial!</a></p></td>";
?>
	</p>
<div id="copyright" class="container">
	<p>© epalte online. All rights reserved. | Designed by dispenserstock team</p>
</div>
</body>
</html>
