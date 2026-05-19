package fun.hykgraph.controller.admin;

import fun.hykgraph.result.Result;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

@RestController
@Slf4j
public class FileUploadController {

    @PostMapping({"/admin/dish/upload", "/api/admin/dish/upload", "/admin/admin/dish/upload"})
    public Result<Map<String, String>> upload(@RequestParam(value = "file", required = false) MultipartFile file) {
        log.info("收到上传请求: file={}", file != null ? file.getOriginalFilename() : "null");
        if (file == null || file.isEmpty()) return Result.error("文件为空");
        String name = file.getOriginalFilename();
        if (name == null) return Result.error("文件名为空");
        if (!name.toLowerCase().matches(".*\\.(png|jpg|jpeg)$")) return Result.error("仅支持PNG/JPG");
        try {
            Path dir = Paths.get(System.getProperty("user.dir"), "dish-images");
            if (!Files.exists(dir)) Files.createDirectories(dir);
            String filename = System.currentTimeMillis() + "_" + name;
            file.transferTo(dir.resolve(filename).toFile());
            String url = "/dish-images/" + filename;
            Map<String, String> m = new HashMap<>();
            m.put("url", url);
            log.info("图片上传成功: {}", url);
            return Result.success(m);
        } catch (IOException e) {
            log.error("上传失败", e);
            return Result.error("上传失败: " + e.getMessage());
        }
    }
}
