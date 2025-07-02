################################################################################
# UK-HWfcast: REAL-TIME FORECAST OF TEMPERATURE-RELATED EXCESS MORTALITY
################################################################################

################################################################################
# MAPS
################################################################################

################################################################################
# MAPS OF EXCESS DEATH RATE AND TEMPERATURE DIFFERENCE WITH MAX

fcastmap <- merge(lsoashp, lookup[c("LSOA11CD","LAD11CD")]) |>
  merge(fcastlsoa[agegr=="all",c("LSOA11CD","date","an","pop","diff")]) |>
  mutate(rate=an/pop*10^6)
ladmap <- merge(ladshp, unique(lookup[c("LAD11CD","RGN11CD")]), sort=F)

colval <- c("white", colorRampPalette(c("yellow","orange","red","red4"))(11))
cutrate <-  c(-1000,0:10*2,1000)
ggplot(data=subset(fcastmap, date=="19 July 2022")) + 
  geom_sf(aes(fill=cut(rate,  cutrate, inc=T)), col=NA) +
  geom_sf(data=ladmap, col=1, fill=NA, size=0.2) +
  scale_fill_manual(values=colval, drop=F,
    name="Heat-related mortality rate (x 1,000,000)") + 
  guides(fill=guide_colorsteps(barwidth=18, barheight=0.6, title.position="top",
    title.hjust=0.5)) +
  theme_void() +
  #facet_wrap(vars(date), labeller=function(x) format(x, format="%d %B %Y")) +
  theme(legend.position="bottom") 

ukfcastdeath <- ggplot(data=fcastmap) + 
  geom_sf(aes(fill=cut(rate,  cutrate, inc=T)), col=NA) +
  geom_sf(data=ladmap, col=1, fill=NA, size=0.2) +
  scale_fill_manual(values=colval, drop=F,
    name="Heat-related mortality rate (x 1,000,000)") + 
  guides(fill=guide_colorsteps(barwidth=18, barheight=0.6, title.position="top",
    title.hjust=0.5)) +
  theme_void() +
  facet_wrap(vars(date)) +
  theme(legend.position="bottom") 

png("figures/fcastdeath.png", height=3400*0.7, width=4000*0.7, res=288)
ukfcastdeath
dev.off()

# pdf("figures/fcastdeath.pdf", height=11.2*0.7, width=13.20*0.7)
# ukfcastdeath
# dev.off()

################################################################################
# MAP OF TEMPERATURE ABOVE MAX

ggplot(data=subset(fcastmap, date=="19 July 2022")) + 
  geom_sf(aes(fill=diff), col=NA) +
  geom_sf(data=ladmap, col=1, fill=NA, size=0.2) +
  scale_fill_steps2(low="green", high="deeppink4", n.breaks=15,
    name="Temperature difference from recorded maximum (Celsius)") + 
  guides(fill=guide_colorsteps(barwidth=18, barheight=0.6, title.position="top",
    title.hjust=0.5)) +
  theme_void() +
  #facet_wrap(vars(date), labeller=function(x) format(x, format="%d %B %Y")) +
  theme(legend.position="bottom")

ukfcastdiff <- ggplot(data=fcastmap) + 
  geom_sf(aes(fill=diff), col=NA) +
  geom_sf(data=ladmap, col=1, fill=NA, size=0.2) +
  scale_fill_steps2(low="green", high="deeppink4", n.breaks=15,
    name="Temperature difference from maximum recorded in 2000-2019") + 
  guides(fill=guide_colorsteps(barwidth=18, barheight=0.6, title.position="top",
    title.hjust=0.5)) +
  theme_void() +
  facet_wrap(vars(date)) +
  theme(legend.position="bottom") 

png("figures/fcastdiff.png", height=3400*0.7, width=4000*0.7, res=288)
ukfcastdiff
dev.off()

################################################################################
# MAP OF REGIONS

# AGGREGATE TO REGIONS, SIMPLIFYING THE SHAPES
regmap <- ladmap %>% 
  merge(unique(lookup[c("RGN11CD","RGN11NM")])) %>%
  group_by(RGN11CD, RGN11NM) %>%  summarise() %>%
  ms_simplify(keep=0.025, keep_shapes=T)

png("figures/regmap.png", height=2000, width=2000, res=288)

ggplot(data=regmap) + 
  geom_sf(aes(fill=factor(RGN11NM, levels=RGN11NM)), col=1) +
  scale_fill_brewer(palette="Paired", name="Region") +
  theme_void() 

dev.off()
