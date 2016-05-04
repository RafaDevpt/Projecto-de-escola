<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>EPALTE Online - Finalizar Compra</title>
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
				<h2 align="center">Finalizar compra</h2>
				<p>
<?php
//iniciar sessao
session_start();
//ligacao a base de dados
include('ligacao_db.php');
//preparar sessao de compra
$sessao = session_id();
if(isset($_SESSION['id_cliente']) == FALSE) {
echo "<tr>Tem de se autenticar para poder continuar a compra!</tr>";
echo "<tr><a href='login.php'>Clique aqui para fazer o login!</a></tr>";}
else {
$id_cliente = $_SESSION['id_cliente'];
$sql_cliente = 'SELECT * FROM clientes WHERE id_cliente='.$id_cliente;
$consulta = mysql_query($sql_cliente);
$mostrar = mysql_fetch_array($consulta);
extract ($mostrar);
//apresentar tabela com os dados do utilizador
echo "<table width='800' border='1' align='center'>";
echo "<tr><td><strong>Passo 1 - Dados para envio </strong></td></tr>";
?>
<tr><td>
<table>
<tr><td>Primeiro Nome: <?php echo $primeiro_nome; ?></td>
</tr>
<tr><td>Apelido: <?php echo $apelido; ?></td>
</tr>
<tr><td>Endereço: <?php echo $endereco; ?></td>
</tr>
<tr><td>Localidade: <?php echo $localidade; ?></td>
</tr>
<tr><td>Código Postal: <?php echo $codigo_postal; ?></td>
</tr>
<tr><td>Email: <?php echo $email; ?></td>
</tr>
</table>
<?php
//pesquisar artigos no carrinho
$sql_carrinho = 'SELECT * FROM compra_temporaria temp JOIN artigos prod ON temp.id_artigo = prod.id_artigo WHERE sessao = "'.$sessao . '"ORDER BY temp.id_artigo ASC';
$consulta = mysql_query($sql_carrinho);
$resultado = mysql_num_rows($consulta);
//apresentar os artigos adicionados ao carrinho
if ($resultado > 0) {
$total = 0;
echo "<table width='800px' border='1' align='center'>";
echo "<th>Imagem artigo</th><th>Detalhe Artigo</th><th>Quantidade</th><th>Preço Unitário</th><th>Total a pagar</th>";
while($mostrar = mysql_fetch_array($consulta)) {
extract($mostrar);
echo "<tr><td align='center' width='100' heigth='100' valign='middle'>
<img src='$pasta_imagens".$imagem_artigo."' border='0'></a>";
echo "<td align='center'>".$descricao_artigo."</td></a>";
echo "<td align='center'>".$quantidade."</td>";
echo "<td align='center'>EUR".$preco_artigo."</td>";
//calcular subtotal
$sub_total = number_format($preco_artigo * $quantidade, 2);
echo "<td align='center'>EUR".$sub_total."</td>";
//calcular valor total de compras
$total = $total + $preco_artigo * $quantidade; }
echo "<tr><td align='right' colspan='5'>O valor total a pagar é de:<strong>EUR".number_format($total,2)."</strong></td></tr>";}
?>
<form method="POST" action="finalizar_compra2.php">
<tr><td colspan="2"><input type="submit" value="Concluir a compra"></td></tr>
</form>
<?php }
?>
	</p>
<div id="copyright" class="container">
	<p>© epalte online. All rights reserved. | Designed by dispenserstock team</p>
</div>
</body>
</html>
