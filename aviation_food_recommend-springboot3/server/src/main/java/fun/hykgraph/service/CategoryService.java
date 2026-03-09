package fun.hykgraph.service;

import fun.hykgraph.dto.CategoryDTO;
import fun.hykgraph.dto.CategoryTypePageDTO;

import fun.hykgraph.entity.Category;
import fun.hykgraph.result.PageResult;

import java.util.List;

public interface CategoryService {
    void addCategory(CategoryDTO categoryDTO);

    PageResult getPageList(CategoryTypePageDTO categoryTypePageDTO);

    List<Category> getList(Integer type);

    Category getById(Integer id);
    void onOff(Integer id);

    void udpate(CategoryDTO categoryDTO);

    void delete(Integer id);

}
