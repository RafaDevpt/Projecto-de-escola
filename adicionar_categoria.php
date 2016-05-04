<?php
//registar categoria
if(isset($_REQUEST['registar'])) {
//ligacao a base de dados
include('ligacao_db.php');
//verificar se ja existe categoria
$sql_categoria = "SELECT nome_categoria FROM categorias";
$consulta1 = mysql_query($sql_categoria);
$resultado = mysql_fetch_array($consulta1);
//verificar se ja existe categoria e definir variavel com o nome
if ($resultado['nome_categoria'] == $_POST['nome_cat']) {
//caso a categoria ja existe, informa o utilizador
echo "Ja existe uma categoria com o nome que inseriu!";
}
else {
//registar nova categoria
$sql_nova_cat= "INSERT INTO categorias(nome_categoria) VALUES('".$_POST['nome_cat']."')";
//$sql_nova_cat= "INSERT INTO categorias(nome_categoria) VALUES('fr4utas')";
$consulta2 = mysql_query($sql_nova_cat);
//remeter para menu
header("Location: menu_admin.php");
}}
?>
<table width="800" border="1" align="center">
<form id="form_registo" name="form_registo" method="POST" action="adicionar_categoria.php">
<td>Nome da categoria: <input type="text" name="nome_cat" size="20" id="nome_cat"/>(obrigatorio)</td>
<p>
<td><input type="submit" name="registar" id="registar" value="Registar"/>
<input type="reset" name="apagar" id="apagar" value="Apagar"/></td>
</p>
</form>
<td colspan="4" align="center"><p>Clique<a href="menu_admin.php"> aqui </a> para voltar ao menu de administraçao</p></td>
</table>