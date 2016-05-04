-- phpMyAdmin SQL Dump
-- version 4.4.11
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: 04-Maio-2016 às 10:00
-- Versão do servidor: 5.6.25
-- PHP Version: 5.3.29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `Epalte_ONLINE`
--

-- --------------------------------------------------------

--
-- Estrutura da tabela `artigos`
--

CREATE TABLE IF NOT EXISTS `artigos` (
  `id_artigo` tinyint(4) NOT NULL,
  `id_categoria` tinyint(4) NOT NULL,
  `nome_artigo` varchar(30) NOT NULL,
  `descricao_artigo` varchar(255) NOT NULL,
  `preco_artigo` double(5,2) NOT NULL,
  `stock_artigo` tinyint(4) NOT NULL,
  `imagem_artigo` varchar(255) NOT NULL,
  `promocao` enum('S','N') NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=latin1;

--
-- Extraindo dados da tabela `artigos`
--

INSERT INTO `artigos` (`id_artigo`, `id_categoria`, `nome_artigo`, `descricao_artigo`, `preco_artigo`, `stock_artigo`, `imagem_artigo`, `promocao`) VALUES
(9, 3, 'cabaz de oliveira', 'cabaz de oliveira', 1.00, 1, 'cabaz de oliveira.jpg', 'S'),
(10, 3, 'cabaz petit', 'cabaz petit', 2.00, 1, 'cabaz petit.jpg', 'S'),
(16, 4, 'arroz doce de figo', 'arroz doce de figo', 1.00, 1, 'arroz doce de figo.jpg', 'S'),
(17, 8, 'bombons de figo', 'os mais doces bombons', 2.00, 1, 'bombons de figo.jpg', 'S');

-- --------------------------------------------------------

--
-- Estrutura da tabela `categorias`
--

CREATE TABLE IF NOT EXISTS `categorias` (
  `id_categoria` tinyint(4) NOT NULL,
  `nome_categoria` varchar(50) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;

--
-- Extraindo dados da tabela `categorias`
--

INSERT INTO `categorias` (`id_categoria`, `nome_categoria`) VALUES
(3, 'cabaz'),
(4, 'arroz'),
(5, 'frutas'),
(6, 'compotas'),
(7, 'licores'),
(8, 'bombons');

-- --------------------------------------------------------

--
-- Estrutura da tabela `clientes`
--

CREATE TABLE IF NOT EXISTS `clientes` (
  `id_cliente` int(10) NOT NULL,
  `nome_login` varchar(12) NOT NULL,
  `palavra_passe` varchar(8) NOT NULL,
  `primeiro_nome` varchar(20) NOT NULL,
  `apelido` varchar(20) NOT NULL,
  `endereco` varchar(50) NOT NULL,
  `localidade` varchar(20) NOT NULL,
  `codigo_postal` char(8) NOT NULL,
  `telefone` int(9) NOT NULL,
  `email` varchar(50) NOT NULL,
  `nivel_utilizador` int(2) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;

--
-- Extraindo dados da tabela `clientes`
--

INSERT INTO `clientes` (`id_cliente`, `nome_login`, `palavra_passe`, `primeiro_nome`, `apelido`, `endereco`, `localidade`, `codigo_postal`, `telefone`, `email`, `nivel_utilizador`) VALUES
(3, 'Rafael_S', 'rafa', 'Rafael', 'Santos', 'alcantas', 'Alcantarilha', '8365', 123456789, 'a1311@epalte.pt', 2),
(4, 'Bruno_B', 'bruno', 'Bruno', 'BrÃ¡s', 'Goncinha', 'LoulÃ©', '8100', 123456789, 'b.bras7@gmail.com', 2),
(5, 'p_martins', 'paula', 'Paula', 'Martins', 'LoulÃ©', 'LoulÃ©', '8100', 123456789, 'paula.martins@epalte.pt', 2);

-- --------------------------------------------------------

--
-- Estrutura da tabela `compra_confirmada`
--

CREATE TABLE IF NOT EXISTS `compra_confirmada` (
  `id_compra` int(5) unsigned NOT NULL,
  `data_compra` datetime NOT NULL,
  `id_cliente` int(10) unsigned NOT NULL,
  `total_pagar` decimal(5,2) NOT NULL,
  `estado_compra` int(2) NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;

--
-- Extraindo dados da tabela `compra_confirmada`
--

INSERT INTO `compra_confirmada` (`id_compra`, `data_compra`, `id_cliente`, `total_pagar`, `estado_compra`) VALUES
(1, '2016-04-28 12:55:09', 3, '2.00', 0),
(2, '2016-04-28 12:58:03', 3, '2.00', 0),
(3, '2016-04-28 14:16:43', 3, '2.00', 0),
(4, '2016-04-28 14:20:39', 3, '2.00', 0),
(5, '2016-04-28 16:07:13', 3, '2.00', 0),
(6, '2016-04-28 16:07:43', 3, '2.00', 0),
(7, '2016-04-28 16:08:19', 5, '2.00', 0),
(8, '2016-05-02 14:39:01', 3, '2.00', 0),
(9, '2016-05-02 14:41:59', 3, '2.00', 0),
(10, '2016-05-02 14:54:55', 3, '2.00', 0);

-- --------------------------------------------------------

--
-- Estrutura da tabela `compra_temporaria`
--

CREATE TABLE IF NOT EXISTS `compra_temporaria` (
  `sessao` char(50) NOT NULL,
  `id_artigo` tinyint(4) NOT NULL,
  `quantidade` int(10) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Extraindo dados da tabela `compra_temporaria`
--

INSERT INTO `compra_temporaria` (`sessao`, `id_artigo`, `quantidade`) VALUES
('a84kn4ijp0ugd8k898o4nno546', 10, 1),
('okmiif09alviu9ud5gk9vbq6d1', 10, 1);

-- --------------------------------------------------------

--
-- Estrutura da tabela `detalhes_compra`
--

CREATE TABLE IF NOT EXISTS `detalhes_compra` (
  `id_compra` int(5) unsigned NOT NULL,
  `quantidade` int(10) unsigned NOT NULL,
  `id_artigo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estrutura da tabela `utilizadores`
--

CREATE TABLE IF NOT EXISTS `utilizadores` (
  `id_utilizador` tinyint(4) NOT NULL,
  `nome_utilizador` varchar(30) NOT NULL,
  `palavra_passe` varchar(30) NOT NULL,
  `email` varchar(40) NOT NULL,
  `nivel_utilizador` tinyint(2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Extraindo dados da tabela `utilizadores`
--

INSERT INTO `utilizadores` (`id_utilizador`, `nome_utilizador`, `palavra_passe`, `email`, `nivel_utilizador`) VALUES
(1, 'administrador', '1234', 'a1305@epalte.pt', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `artigos`
--
ALTER TABLE `artigos`
  ADD PRIMARY KEY (`id_artigo`);

--
-- Indexes for table `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indexes for table `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`);

--
-- Indexes for table `compra_confirmada`
--
ALTER TABLE `compra_confirmada`
  ADD PRIMARY KEY (`id_compra`);

--
-- Indexes for table `compra_temporaria`
--
ALTER TABLE `compra_temporaria`
  ADD PRIMARY KEY (`sessao`,`id_artigo`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `artigos`
--
ALTER TABLE `artigos`
  MODIFY `id_artigo` tinyint(4) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=18;
--
-- AUTO_INCREMENT for table `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id_categoria` tinyint(4) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=9;
--
-- AUTO_INCREMENT for table `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(10) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `compra_confirmada`
--
ALTER TABLE `compra_confirmada`
  MODIFY `id_compra` int(5) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=11;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
