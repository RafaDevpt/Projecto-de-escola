<?php
//ligacao a base de dados
include('ligacao_db.php');
$cat_prod = $_POST["cat_prod"];
$nome_prod = $_POST["nome_prod"];
$desc_prod = $_POST["desc_prod"];
$preco_prod = $_POST["preco_prod"];
$stock_prod = $_POST["stock_prod"];
$img_nome = $_FILES["imagem"]["name"];
//determinar o tamanho e o tipo de ficheiro enviado
$img_tamanho = round($_FILES['imagem']['size']/1000);
$img_tipo = $_FILES['imagem'] ['type'];
$local_final = "$pasta_imagens.$img_nome";
//caso o tamanho ou tipo de ficheiro seja correcto, permite upload
if ($img_tamanho < 350 && ($img_tipo == "image/jpeg" or $img_tipo == "image/pjpeg")) {
//copiar ficheiro para o destino
(move_uploaded_file($_FILES['imagem']['tmp_name'], $local_final));
//inserir hiperligacao na base de dados
$sql_regista = "INSERT INTO artigos(id_categoria, nome_artigo, descricao_artigo, preco_artigo, stock_artigo, imagem_artigo) VALUES ('$cat_prod', '$nome_prod', '$desc_prod', '$stock_prod', '$img_nome')";
$consulta = mysql_query($sql_regista);
//confirmar registo do artigo
echo "O registo foi efetuado com sucesso!";
}
//caso nao seja feito upload da imagem, informa sobre o erro
else {
echo "<p>Nao foi possivel registar os dados devido a um erro no ficheiro de imagem.";
if ($img_tamanho > 350){
echo"<p>O ficheiro submetido tem o tamanho de ".$img_tamanho ."kb!</br>";
}
else {
echo "<p> O ficheiro submetido e do tipo". $img_tipo."!</br>";}
echo "<p> O ficheiro submetido nao pode ultrapassar os 350 kb ou ter formato diferente de JPEG!</br>";
}
?>
<p><a href="menu_admin.php">Clique aqui para continuar</a></p>