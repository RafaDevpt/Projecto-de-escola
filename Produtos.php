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
	<div id="menu-wrapper">
		<div id="menu" class="container">
			<ul>
				<li><a href="index.php">Homepage</a></li>
				<li><a href="Sobre.php">Sobre</a></li>
				<li class="current_page_item"><a href="Produtos.php">Produtos</a></li>
				<li><a href="Politica de Privacidade.php">Politica de Privacidade</a></li>
				<li><a href="Contacto.php">Contacto</a></li>
				<li><a href="Carrinho.php">Carrinho</a></li>
				<li><a href="login.php">Login</a></li>
			</ul>
		</div> 
	</div>
	<div id="banner"></div>
	<table width='800px' border='1' align='center'>
	<form id="form_registo" name="form_registo" method="POST" action="pesquisa_artigo.php">
	<td>Pesquisar...<input type="text" name="termo_pesquisa" size="20"/>(campo obrigatorio)</td>
	<p><td><input type="submit" name="pesquisar" id="Pesquisar"/>
	<input type="reset" name="apagar" id="apagar" value="Apagar"/></td>
	</tr>
	</form>
	</table>
	<div id="page" class="container" style="left: 0px; top: 0px; height: 990px">
<td align='50'>
<?php
//procurar 5 artigos aleatoriamente
$sql_artigo ="SELECT * FROM artigos ORDER BY RAND() LIMIT 5";
$consulta = mysql_query($sql_artigo);
//mostra os artigos encontrados
echo"<table colspan='5' width='800px' border='0' cellpadding='0' cellspacing='0' align='center'>";
while($mostrar = mysql_fetch_array($consulta)){
	echo"<th align='center' width='150' height='100' valign='middle'><a href='comprar.php'?id_artigo=".$mostrar['id_artigo']."'>".$mostrar['nome_artigo']."</th>";
	echo"<a href='comprar.php?id_artigo=".$mostrar['id_artigo']."><img src='$pasta_imagens".$mostrar['imagem_artigo']."'border='0'>";
}
echo"</table>";
?>
</table>
	<div id="page" class="container" style="left: 0px; top: 0px; height: 990px">
<td align='50'>
<div id="sidebar">
			<div class="box2">
			<tr>
			</div>
		</div>
	</div>
</div>
<div id="copyright" class="container">
	<p>EPALTE ONLINE. All rights reserved. | Designed by dispenserstock team</p>
</div>
</body>
</html>
