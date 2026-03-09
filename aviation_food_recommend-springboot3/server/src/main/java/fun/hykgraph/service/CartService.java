package fun.hykgraph.service;

import fun.hykgraph.dto.CartDTO;

import fun.hykgraph.entity.Cart;

import java.util.List;

public interface CartService {
    void add(CartDTO cartDTO);

    List<Cart> getList();

    void clean();

    void sub(CartDTO cartDTO);
}
