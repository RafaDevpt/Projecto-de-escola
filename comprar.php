<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>EPALTE Online - Produtos</title>
<link href="../default.css" rel="stylesheet" type="text/css" media="all" />
<link href="fonts.css" rel="stylesheet" type="text/css" media="all" />
<link href="../GridView.css" rel="stylesheet" type="text/css"/>
<!--[if IE 6]>
<link href="default_ie6.css" rel="stylesheet" type="text/css" />
<![endif]-->
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
					<table width="800" border="0" align="center" cellspacing="0">
			<tr>
			<form id="form_registo" name="form_registo" method="post" action="processa_login.php">
			<td align="left" valign="top">Nome de Utilizador:
			<input type="text" name="nome" id="nome"/>Palavra-Passe:
			<input type="password" name="password" id="password"/>
			<a href="registo_cliente.php">Novo Utilizador?</a></td>
			<tr><td><input type="reset" name="apagar" id="apagar" value="Apagar"/></td></tr>
			<tr><td><input type="submit" name="confirmar" id="confirmar" value="confirmar"/></td></tr>
			</form>
			</tr>
			</table>
	<div id="menu-wrapper">
		<div id="menu" class="container">
			<ul>
				<li><a href="index.php">Homepage</a></li>
				<li><a href="Sobre.php">Sobre</a></li>
				<li class="current_page_item"><a href="Produtos.php">Produtos</a></li>
				<li><a href="Politica de Privacidade.php">Politica de Privacidade</a></li>
				<li><a href="Contacto.php">Contacto</a></li>
				<li><a href="Carrinho.php">Carrinho</a></li>
			</ul>
		</div> 
	</div>
	<div id="banner"></div>
	<div id="page" class="container" style="left: 0px; top: 0px; height: 990px">
<td align='50'>
		<div id="sidebar">
			<div align="center" class="box2">
			<tr></tr>
			<tr>
			<td></td>
			</tr>
<?php
//iniciar sessao
session_start();
//ligacao a base de dados
include('ligacao_db.php');
//capturar codigo de artigo
$id_artigo = $_REQUEST['id_artigo'];
//preparar sessao de compra
$sessao = session_id();
//pesquisar artigo seleccionado
//$sql_artigo = "SELECT * FROM artigos WHERE id_artigo = ".$id_artigo;
$sql_artigo = 'SELECT * FROM artigos WHERE id_artigo = "'.$id_artigo.'"';
$consulta1 = mysql_query($sql_artigo);
$mostrar = mysql_fetch_array($consulta1);
//mostrar detalhes do artigo seleccionado
echo"<table width='800px' border='1' align='center'>";
echo"<p align='center'><a href=\"Carrinho.php\">Ver lista de compras</a></p>";
echo"<p align='center'><a href=\"Produtos.php\">Ver todos os artigos</a></p>";
echo"<strong><p align='center'>Voce selecionou os seguintes artigos: </strong></p><td align='center' width='100' valign='middle'><img src='$pasta_imagens".$mostrar['imagem_artigo']."'border='0'>";
echo"<td><align='center'>".$mostrar['nome_artigo']."</a></br>EUR".$mostrar['preco_artigo']."</br>".$mostrar['descricao_artigo']."</br>";
//selecionar quantidade temporaria
$sql_quantidade = 'SELECT quantidade FROM compra_temporaria WHERE sessao="'.$sessao.'"AND id_artigo="'.$id_artigo.'"';
$consulta2 = mysql_query($sql_quantidade);
$resultado = mysql_fetch_assoc($consulta2);
//se houver quantidades ja ibnseridas, mostra valor
if (mysql_num_rows($consulta2)>0) { $quantidade =  $resultado['quantidade']; }
//se nao houver quantidade ja inserida, atribui valor zero
else{$quantidade=0;}
//inicar formulario para atualizar valores de quantidade
echo'<form method="POST" action="atualizar_compra.php">';
//apresentar quantiade a zero ou o numero de vezes seleccionado
echo'<p>Quantidade: <input type="text" name="quantidade" id="quantidade" size="2" value"'.$quantidade.'"/>';
/* se a quantidade for positiva, permite alterar ou remover quantidade/artigo */
if($quantidade > 0) {
	echo '<align="center"><input type="submit" name="submit" value="Alterar"/>';
	echo '<align="center"><input type="submit" name="submit" value="Remover Artigo"/>';
	//se a quantidade for nula, permite adicionar artigo
}else{
	echo'<align="center"><input type="submit" name="submit" value="Adicionar"/>';}
	echo'<input type="hidden" name="id_artigo" value="'.$id_artigo.'"/>';
	echo"</form>";
	echo"</table>";
?>
</td>
</div>
</div>
		</div>
	</div>
</body>
</html>
