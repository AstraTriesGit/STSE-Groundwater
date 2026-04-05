library(sf)
library(ggplot2)

aquifers <- read_sf("data/shp/aquifers/Major_Aquifers.shp")

ggplot() +
  geom_sf(mapping = aes(fill = aquifer), data = aquifers, linewidth = 0.1)

ggsave("die.png", dpi = 450)

png("whatever.png",
    width = 1500, height = 1500, units = "px")
plot(aquifers[, 2])
dev.off()
