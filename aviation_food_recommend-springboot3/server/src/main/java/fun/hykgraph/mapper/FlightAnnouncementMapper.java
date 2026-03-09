package fun.hykgraph.mapper;

import fun.hykgraph.entity.FlightAnnouncement;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface FlightAnnouncementMapper {

    List<FlightAnnouncement> list(Integer flightId);

    void insert(FlightAnnouncement announcement);

    void update(FlightAnnouncement announcement);

    void deleteById(Integer id);
}
