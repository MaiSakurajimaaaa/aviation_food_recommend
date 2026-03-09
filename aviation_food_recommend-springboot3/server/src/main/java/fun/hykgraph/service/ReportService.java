package fun.hykgraph.service;

import fun.hykgraph.vo.OrderReportVO;
import fun.hykgraph.vo.SalesTop10ReportVO;
import fun.hykgraph.vo.TurnoverReportVO;

import fun.hykgraph.vo.UserReportVO;

import jakarta.servlet.http.HttpServletResponse;
import java.time.LocalDate;

public interface ReportService {
    TurnoverReportVO getTurnover(LocalDate begin, LocalDate end);

    UserReportVO getUser(LocalDate begin, LocalDate end);

    OrderReportVO getOrder(LocalDate begin, LocalDate end);

    SalesTop10ReportVO getSalesTop10(LocalDate begin, LocalDate end);

    void exportBusinessData(HttpServletResponse response);
}
