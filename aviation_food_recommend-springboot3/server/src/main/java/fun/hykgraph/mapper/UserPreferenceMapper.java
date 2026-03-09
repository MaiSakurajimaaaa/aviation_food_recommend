package fun.hykgraph.mapper;

import fun.hykgraph.entity.UserPreference;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface UserPreferenceMapper {

    @Select("select * from user_preference where user_id = #{userId} limit 1")
    UserPreference getByUserId(Integer userId);

    void insert(UserPreference preference);

    void update(UserPreference preference);
}
