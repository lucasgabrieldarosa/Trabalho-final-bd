
-- Scripts de criação da base de dados e tabelas

CREATE TABLE Cliente (
    id_cliente SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(15)
);

CREATE TABLE Categoria (
    id_categoria SERIAL PRIMARY KEY,
    nome_categoria VARCHAR(50) NOT NULL
);

CREATE TABLE Produto (
    id_produto SERIAL PRIMARY KEY,
    nome_produto VARCHAR(100) NOT NULL,
    preco DECIMAL(10, 2) NOT NULL,
    id_categoria INT REFERENCES Categoria(id_categoria)
);

CREATE TABLE Pedido (
    id_pedido SERIAL PRIMARY KEY,
    id_cliente INT REFERENCES Cliente(id_cliente),
    data_pedido DATE NOT NULL
);


CREATE TABLE Item_Pedido (
    id_item SERIAL PRIMARY KEY,
    id_pedido INT REFERENCES Pedido(id_pedido),
    id_produto INT REFERENCES Produto(id_produto),
    quantidade INT NOT NULL,
    valor_total DECIMAL(10, 2) NOT NULL
);


---- Junções e views

CREATE VIEW relatorio_pedidos_clientes AS
SELECT 
    c.nome AS cliente,
    p.id_pedido AS pedido,
    p.data_pedido AS data,
    SUM(i.valor_total) AS total_pedido
FROM Cliente c
JOIN Pedido p ON c.id_cliente = p.id_cliente
JOIN Item_Pedido i ON p.id_pedido = i.id_pedido
GROUP BY c.nome, p.id_pedido, p.data_pedido;

----

CREATE VIEW produtos_categoria AS
SELECT 
    cat.nome_categoria AS categoria,
    prod.nome_produto AS produto,
    prod.preco AS preco
FROM Categoria cat
JOIN Produto prod ON cat.id_categoria = prod.id_categoria;



--- criação de usuários, grupos e concessão de privilégios

-- Adm
CREATE ROLE admin WITH LOGIN PASSWORD 'admin123';

-- Vendedores
CREATE ROLE vendedor WITH LOGIN PASSWORD 'vendedor123';

--Privilégios
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO admin;
GRANT SELECT, INSERT ON Pedido, Item_Pedido TO vendedor;


--- Triggers
--Atualizar o pedido automaticamente
CREATE OR REPLACE FUNCTION atualizar_total_pedido()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Pedido
    SET total = (
        SELECT SUM(valor_total)
        FROM Item_Pedido
        WHERE id_pedido = NEW.id_pedido
    )
    WHERE id_pedido = NEW.id_pedido;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_total
AFTER INSERT OR UPDATE ON Item_Pedido
FOR EACH ROW
EXECUTE FUNCTION atualizar_total_pedido();


--Impedir que exclua categorias com produtos vinculados

CREATE OR REPLACE FUNCTION impedir_exclusao_categoria()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Produto WHERE id_categoria = OLD.id_categoria) THEN
        RAISE EXCEPTION 'Não é possível excluir uma categoria com produtos vinculados.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_categoria
BEFORE DELETE ON Categoria
FOR EACH ROW
EXECUTE FUNCTION impedir_exclusao_categoria();




