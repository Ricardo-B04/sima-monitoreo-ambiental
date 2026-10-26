# Complemento de 04_modelado y evaluación.Rmd, sección 13.
# Ejecutar desde el Rmd después de la sección 12, mediante source(...,local=TRUE).
# Los modelos originales y la base permanecen disponibles en el mismo entorno.
# Los reajustes de sensibilidad del GAMM de CE están desactivados por defecto.
# Los archivos RDS son cachés locales regenerables, no entradas indispensables.
suppressPackageStartupMessages({library(dplyr);library(mgcv);library(splines)})
stopifnot(exists('base_cierre'),exists('ajustes_cierre'),exists('modelos_gam'),
  exists('ajustar_ar1'),exists('predecir_ar1'))
revision <- raiz
salida <- file.path(raiz,'analisis/salidas/retro_etapa3')
dir.create(salida,recursive=TRUE,showWarnings=FALSE)
set.seed(5821)
guardar <- function(x,n)write.csv(x,file.path(salida,paste0(n,'.csv')),row.names=FALSE,fileEncoding='UTF-8')
mensaje <- function(x){cat(format(Sys.time()),x,'\n');flush.console()}
obj <- list(logistica=ajustes_cierre,gam=list(Log1p_CE=modelos_gam[['CE']]))
anterior <- obj$logistica[['60_Log1p']]
base <- bind_rows(anterior$entrenamiento,anterior$prueba) |> arrange(estacion,dia)
base$estacion <- factor(base$estacion)
vars <- c('log_NO_media','log_NO2_media','TOUT_max','SR_media','RH_media','PRS_media','U_media','V_media')
calendario <- c('doy_sin','doy_cos','doy_sin2','doy_cos2')
pred <- c(vars,calendario)
form_lm <- reformulate(pred,response='O3_max8')
form_glm <- reformulate(c('estacion',pred),response='evento')
form_flex <- reformulate(c('estacion',paste0('splines::ns(',vars,', df=3)'),calendario),response='evento')
form_gam <- reformulate(c(paste0('s(',vars,', k=5)'),calendario),response='O3_max8')
met <- function(y,p,c=.5) {
  z<-p>=c;vp<-sum(z&y==1);fn<-sum(!z&y==1);fp<-sum(z&y==0);vn<-sum(!z&y==0)
  data.frame(n=length(y),VP=vp,FN=fn,FP=fp,VN=vn,
    sensibilidad=vp/(vp+fn),especificidad=vn/(vn+fp),precision=if(vp+fp)vp/(vp+fp) else NA_real_,
    F1=if(2*vp+fp+fn)2*vp/(2*vp+fp+fn) else NA_real_,EB=(vp/(vp+fn)+vn/(vn+fp))/2,
    Brier=mean((p-y)^2),logloss=-mean(y*log(pmax(p,1e-10))+(1-y)*log(pmax(1-p,1e-10))))
}
corte <- function(y,p) {
  t<-bind_rows(lapply(seq(0,1,.01),function(c)cbind(corte=c,met(y,p,c))))
  t<-t[order(-t$EB,-t$sensibilidad,t$corte),];t$corte[1]
}
validar_glm <- function(m) stopifnot(m$converged,all(is.finite(coef(m))))
ajustar_glm_retro <- function(f,d) {
  avisos<-character()
  m<-withCallingHandlers(glm(f,data=d,family=binomial()),warning=function(w){
    avisos<<-c(avisos,conditionMessage(w));invokeRestart('muffleWarning')})
  attr(m,'advertencia_retro')<-paste(avisos,collapse='; ')
  m
}
# Remuestreo de bloques de días calendario; cada bloque conserva juntas todas
# las estaciones. Se remuestrean predicciones fijas, sin reajustar los modelos.
indices_bloques <- function(d, largo=7L, B=2000L) {
  fechas<-seq(min(d$dia),max(d$dia),by='day');nd<-length(fechas)
  por_fecha<-split(seq_len(nrow(d)),factor(d$dia,levels=as.character(fechas)))
  inicios<-seq_len(nd-largo+1L)
  lapply(seq_len(B),function(b) {
    dias<-unlist(lapply(sample(inicios,ceiling(nd/largo),replace=TRUE),function(i)i+0:(largo-1L)),use.names=FALSE)[seq_len(nd)]
    unlist(por_fecha[dias],use.names=FALSE)
  })
}
intervalos <- function(d,modelos,largo=7L,B=2000L) {
  ids<-indices_bloques(d,largo,B);res<-list();dif<-list()
  for(n in names(modelos)) {
    a<-modelos[[n]];p<-a$p;c<-a$c
    b<-bind_rows(lapply(ids,function(i)met(d$evento[i],p[i],c)))
    est<-met(d$evento,p,c)
    res[[n]]<-bind_rows(lapply(c('sensibilidad','precision','F1','EB','Brier'),function(v)
      data.frame(modelo=n,metrica=v,estimacion=est[[v]],inferior=quantile(b[[v]],.025,na.rm=TRUE),
        superior=quantile(b[[v]],.975,na.rm=TRUE),bloque=largo,replicas=B)))
    dif[[n]]<-b
  }
  if(all(c('Original','AR1')%in%names(dif))) {
    res[['Diferencia_AR1_Original']]<-bind_rows(lapply(c('sensibilidad','precision','F1','EB','Brier'),function(v) {
      b<-dif$AR1[[v]]-dif$Original[[v]]
      data.frame(modelo='Diferencia_AR1_Original',metrica=v,
        estimacion=met(d$evento,modelos$AR1$p,modelos$AR1$c)[[v]]-met(d$evento,modelos$Original$p,modelos$Original$c)[[v]],
        inferior=quantile(b,.025,na.rm=TRUE),superior=quantile(b,.975,na.rm=TRUE),bloque=largo,replicas=B)
    }))
  }
  bind_rows(res)
}
mensaje('Interpretación de variables')
tr<-filter(base,anio<=2024)
lineales<-lapply(split(tr,tr$estacion,drop=TRUE),function(d)lm(form_lm,d))
ef_lm<-bind_rows(lapply(names(lineales),function(e) {
  d<-filter(tr,estacion==e);b<-coef(lineales[[e]])
  data.frame(estacion=e,variable=vars,beta=b[vars],cambio_IQR_ppb=b[vars]*vapply(d[vars],IQR,numeric(1)))
}))
guardar(ef_lm,'lineal_efectos')
guardar(ef_lm |> group_by(variable) |> summarise(mediana_IQR_ppb=median(cambio_IQR_ppb),
  positivos=sum(beta>0),negativos=sum(beta<0),estaciones=n(),.groups='drop'),'lineal_resumen')
ef_log<-bind_rows(lapply(c(60,51),function(u) {
  m<-obj$logistica[[paste0(u,'_Log1p')]]$modelo;b<-coef(m)[vars]
  q<-vapply(tr[vars],IQR,numeric(1))
  data.frame(umbral=u,variable=vars,beta=b,log_OR_IQR=b*q,OR_IQR=exp(b*q))
}))
guardar(ef_log,'logistica_efectos')
# El GAMM se recuperó del caché original que sí contiene el ajuste de CE.
archivo_gamm <- file.path(salida,'gamm_original_ce.rds')
if (exists('modelo_gamm_ce')) {
  gamm <- modelo_gamm_ce
} else if (file.exists(archivo_gamm)) {
  gamm <- readRDS(archivo_gamm)
} else {
  datos_gamm <- filter(tr,estacion=='CE')
  datos_gamm$tiempo <- as.integer(datos_gamm$dia-as.Date('2021-01-01'))
  gamm <- mgcv::gamm(form_gam,data=datos_gamm,family=gaussian(),
    correlation=nlme::corAR1(form=~tiempo),method='REML',na.action=na.fail,
    control=nlme::lmeControl(niterEM=0,msMaxIter=200,msMaxEval=400))
}
saveRDS(gamm,archivo_gamm)

ce<-filter(tr,estacion=='CE')
stopifnot(nrow(gamm$gam$model)==nrow(ce),max(abs(gamm$gam$model$O3_max8-ce$O3_max8))<1e-10)
term_gamm<-predict(gamm$gam,ce,type='terms');term_gam<-predict(obj$gam$Log1p_CE,ce,type='terms')
amp<-function(x)unname(diff(quantile(x,c(.1,.9))))
gamm_vars<-bind_rows(lapply(vars,function(v) {
  n<-paste0('s(',v,')');g<-ce[rep(1,100),];for(w in pred)g[[w]]<-median(ce[[w]])
  g[[v]]<-seq(quantile(ce[[v]],.05),quantile(ce[[v]],.95),length.out=100)
  a<-as.numeric(predict(gamm$gam,g,type='terms')[,n])
  data.frame(variable=v,amplitud_GAM=amp(term_gam[,n]),amplitud_GAMM=amp(term_gamm[,n]),
    cambio_extremos_GAMM=a[100]-a[1],minimo_x=g[[v]][which.min(a)],maximo_x=g[[v]][which.max(a)],
    rango_x_min=min(g[[v]]),rango_x_max=max(g[[v]]))
}))
guardar(gamm_vars,'gamm_variables')
saveRDS(list(base=base,lineales=lineales,gamm=gamm,formula_gam=form_gam),file.path(salida,'base_ampliacion.rds'),compress=FALSE)
mensaje('Datos faltantes y selección de casos')
d<-read.csv(file.path(revision,'datos/procesados/sima_diaria_estacion.csv'))
d$dia<-as.Date(d$dia);d<-filter(d,anio%in%2021:2025)
d$completo_final<-complete.cases(d[c('O3_max8',vars)])
d$mes<-as.integer(format(d$dia,'%m'))
faltantes<-d |> group_by(completo_final) |> summarise(total=n(),ozono_valido=sum(!is.na(O3_max8)),
  ozono_mediano=median(O3_max8,na.rm=TRUE),excedencia60=mean(exc_60,na.rm=TRUE),
  excedencia51=mean(exc_51,na.rm=TRUE),temperatura_mediana=median(TOUT_max,na.rm=TRUE),
  humedad_mediana=median(RH_media,na.rm=TRUE),radiacion_mediana=median(SR_media,na.rm=TRUE),.groups='drop')
guardar(faltantes,'faltantes_grupos')
guardar(d |> group_by(anio,completo_final) |> summarise(total=n(),ozono_valido=sum(!is.na(O3_max8)),
  ozono_mediano=median(O3_max8,na.rm=TRUE),excedencia60=mean(exc_60,na.rm=TRUE),.groups='drop'),'faltantes_anio')
guardar(d |> group_by(estacion) |> summarise(total=n(),completos=sum(completo_final),
  cobertura=mean(completo_final),.groups='drop'),'faltantes_estacion')
guardar(d |> group_by(mes) |> summarise(total=n(),cobertura=mean(completo_final),.groups='drop'),'faltantes_mes')
mensaje('Linealidad del logit y alternativa de curvas')
curvaturas<-diagnosticos<-list();ajustes_flex<-list()
for(u in c(60,51)) {
  z<-base;z$evento<-z[[paste0('exc_',u)]]
  a<-filter(z,anio<=2023);v<-filter(z,anio==2024);f<-filter(z,anio<=2024);p<-filter(z,anio==2025)
  m0<-glm(form_glm,a,family=binomial());mf<-glm(form_flex,a,family=binomial());validar_glm(mf)
  p0<-predict(m0,v,type='response');pf<-predict(mf,v,type='response')
  vv<-v;vv$diferencia<-(-v$evento*log(pmax(pf,1e-10))-(1-v$evento)*log(pmax(1-pf,1e-10)))-
    (-v$evento*log(pmax(p0,1e-10))-(1-v$evento)*log(pmax(1-p0,1e-10)))
  ids<-indices_bloques(vv,7,2000)
  boot<-vapply(ids,function(i)mean(vv$diferencia[i]),numeric(1))
  diagnosticos[[paste0(u,'_global')]]<-data.frame(umbral=u,variable='Todas_curvas',
    logloss_lineal=met(v$evento,p0)$logloss,logloss_curvas=met(v$evento,pf)$logloss,
    diferencia=mean(vv$diferencia),inferior=quantile(boot,.025),superior=quantile(boot,.975))
  for(w in vars) {
    ff<-reformulate(c('estacion',setdiff(pred,w),paste0('splines::ns(',w,', df=3)')),response='evento')
    mm<-glm(ff,a,family=binomial());validar_glm(mm);pm<-predict(mm,v,type='response')
    dif_w<-(-v$evento*log(pmax(pm,1e-10))-(1-v$evento)*log(pmax(1-pm,1e-10)))-
      (-v$evento*log(pmax(p0,1e-10))-(1-v$evento)*log(pmax(1-p0,1e-10)))
    boot_w<-vapply(ids,function(i)mean(dif_w[i]),numeric(1))
    diagnosticos[[paste(u,w)]]<-data.frame(umbral=u,variable=w,
      logloss_lineal=met(v$evento,p0)$logloss,logloss_curvas=met(v$evento,pm)$logloss,
      diferencia=mean(dif_w),inferior=quantile(boot_w,.025),superior=quantile(boot_w,.975))
    g<-a[rep(1,100),];for(ww in pred)g[[ww]]<-median(a[[ww]])
    g[[w]]<-seq(quantile(a[[w]],.05),quantile(a[[w]],.95),length.out=100)
    l<-as.numeric(predict(mm,g,type='link'));cent<-l-l[50]
    curvaturas[[paste(u,w)]]<-data.frame(umbral=u,variable=w,x=g[[w]],logit_centrado=cent,
      desviacion_recta=l-as.numeric(predict(lm(l~g[[w]]))))
  }
  modelo<-glm(form_flex,f,family=binomial());validar_glm(modelo)
  ajustes_flex[[as.character(u)]]<-list(modelo=modelo,corte=corte(v$evento,pf),
    prueba=transform(p,prob_flex=as.numeric(predict(modelo,p,type='response'))))
}
guardar(bind_rows(diagnosticos),'diagnostico_logit')
guardar(bind_rows(curvaturas),'curvas_logit')
saveRDS(ajustes_flex,file.path(salida,'ajustes_flex.rds'))
mensaje('Validación con cortes temporales 2023, 2024 y 2025')
rolling<-pred_rolling<-conc_rolling<-control_rolling<-list()
for(y in 2023:2025) {
  for(u in c(60,51)) {
    z<-base;z$evento<-z[[paste0('exc_',u)]]
    a<-filter(z,anio<=y-2);v<-filter(z,anio==y-1);f<-filter(z,anio<y);p<-filter(z,anio==y)
    # Una estación ausente del ajuste inicial no tiene intercepto estimable.
    # Las tres alternativas se comparan sobre las mismas estaciones conocidas.
    conocidas<-unique(as.character(a$estacion))
    v<-filter(v,as.character(estacion)%in%conocidas)
    f<-filter(f,as.character(estacion)%in%conocidas)
    p<-filter(p,as.character(estacion)%in%conocidas)
    stopifnot(max(a$anio)<min(v$anio),max(f$anio)<y)
    for(n in c('Original','Curvas')) {
      ff<-if(n=='Original')form_glm else form_flex
      m1<-ajustar_glm_retro(ff,a);m2<-ajustar_glm_retro(ff,f);validar_glm(m1);validar_glm(m2)
      for(et in c('Inicial','Final')) {
        mm<-if(et=='Inicial')m1 else m2
        control_rolling[[paste(y,u,n,et)]]<-data.frame(anio=y,umbral=u,modelo=n,etapa=et,
          advertencia=attr(mm,'advertencia_retro'),convergio=mm$converged,
          prob_min=min(fitted(mm)),prob_max=max(fitted(mm)))
      }
      pp<-as.numeric(predict(m2,p,type='response'));cv<-corte(v$evento,predict(m1,v,type='response'))
      rolling[[paste(y,u,n)]]<-cbind(anio=y,umbral=u,modelo=n,corte=cv,met(p$evento,pp,cv))
      pred_rolling[[paste(y,u,n)]]<-data.frame(anio=y,umbral=u,modelo=n,estacion=p$estacion,dia=p$dia,evento=p$evento,prob=pp,corte=cv)
    }
    # Persistencia estricta de un día calendario, no último registro disponible.
    # Si falta el día anterior, se usa la frecuencia del entrenamiento de su estación.
    llave<-paste(d$estacion,d$dia);j<-match(paste(p$estacion,p$dia-1),llave)
    pasado<-d[[paste0('exc_',u)]][j];freq<-tapply(f$evento,f$estacion,mean)
    pp<-ifelse(is.na(pasado),freq[as.character(p$estacion)],pasado)
    stopifnot(!anyNA(pp))
    rolling[[paste(y,u,'Persistencia')]]<-cbind(anio=y,umbral=u,modelo='Persistencia',corte=.5,met(p$evento,pp))
    pred_rolling[[paste(y,u,'Persistencia')]]<-data.frame(anio=y,umbral=u,modelo='Persistencia',estacion=p$estacion,dia=p$dia,evento=p$evento,prob=pp,corte=.5)
    guardar(data.frame(anio=y,umbral=u,casos=nrow(p),sin_dia_previo=sum(is.na(pasado))),paste0('persistencia_cobertura_',y,'_',u))
  }
  # Las concentraciones se comparan también en varios años, con igual muestra.
  for(e in levels(base$estacion)) {
    tr_e<-filter(base,estacion==e,anio<y);te_e<-filter(base,estacion==e,anio==y)
    if(nrow(tr_e)<=40||!nrow(te_e))next
    lm_e<-lm(form_lm,tr_e);gam_e<-gam(form_gam,tr_e,method='REML',family=gaussian())
    for(n in c('Lineal','GAM')) {
      pp<-predict(if(n=='Lineal')lm_e else gam_e,te_e,type='response')
      conc_rolling[[paste(y,e,n)]]<-data.frame(anio=y,estacion=e,modelo=n,n=nrow(te_e),
        RMSE=sqrt(mean((pp-te_e$O3_max8)^2)),sesgo=mean(pp-te_e$O3_max8))
    }
  }
  mensaje(paste('Corte terminado',y))
  guardar(bind_rows(rolling),'validacion_temporal');guardar(bind_rows(pred_rolling),'predicciones_temporales')
  guardar(bind_rows(conc_rolling),'concentraciones_temporales')
  guardar(bind_rows(control_rolling),'control_glm_temporal')
}
mensaje('Intervalos por bloques y persistencia de 2025')
ar<-read.csv(file.path(revision,'analisis/salidas/cierre/ar1_predicciones.csv'));ar$dia<-as.Date(ar$dia)
cortes_ar<-read.csv(file.path(revision,'analisis/salidas/cierre/ar1_cortes.csv'))
intervalos_todos<-comparaciones<-list()
for(u in c(60,51)) {
  z<-filter(ar,umbral==u,anio==2025);r<-bind_rows(pred_rolling) |> filter(umbral==u,anio==2025)
  obtener<-function(n) {
    a<-filter(r,modelo==n);a[match(paste(z$estacion,z$dia),paste(a$estacion,a$dia)),]
  }
  orig<-obtener('Original');flex<-obtener('Curvas');pers<-obtener('Persistencia')
  stopifnot(all(orig$evento==z$evento),max(abs(orig$prob-z$prob_original))<1e-8)
  ca<-filter(cortes_ar,umbral==u,criterio=='Balanceada',modelo=='AR1')$corte
  mods<-list(Original=list(p=z$prob_original,c=orig$corte[1]),AR1=list(p=z$prob_ar1,c=ca),
    Curvas=list(p=flex$prob,c=flex$corte[1]),Persistencia=list(p=pers$prob,c=.5))
  for(n in names(mods))comparaciones[[paste(u,n)]]<-cbind(umbral=u,modelo=n,corte=mods[[n]]$c,met(z$evento,mods[[n]]$p,mods[[n]]$c))
  for(l in c(7,14))intervalos_todos[[paste(u,l)]]<-cbind(umbral=u,intervalos(z,mods,l,2000))
}
guardar(bind_rows(comparaciones),'comparacion_2025_ampliada')
guardar(bind_rows(intervalos_todos),'intervalos_bloques')
mensaje('Sensibilidad de regresión lineal ante ambas reglas de calidad')
cal_lm<-list()
for(e in names(lineales)) {
  a<-filter(base,estacion==e,anio<=2024);p<-filter(base,estacion==e,anio==2025)
  if(!nrow(p))next
  for(regla in c('Inicial','Ampliada')) {
    ia<-if(regla=='Inicial')!(a$revisar_SR|a$revisar_RH) else !a$senalado
    ip<-if(regla=='Inicial')!(p$revisar_SR|p$revisar_RH) else !p$senalado
    if(sum(ia)<30||!sum(ip))next
    ms<-lm(form_lm,a[ia,]);te<-p[ip,]
    for(n in c('Todos','Sin_senalados')) {
      pp<-predict(if(n=='Todos')lineales[[e]] else ms,te)
      cal_lm[[paste(e,regla,n)]]<-data.frame(estacion=e,regla=regla,modelo=n,
        n_ajuste=if(n=='Todos')nrow(a) else sum(ia),n_prueba=nrow(te),
        RMSE=sqrt(mean((pp-te$O3_max8)^2)),sesgo=mean(pp-te$O3_max8))
    }
  }
}
guardar(bind_rows(cal_lm),'lineal_calidad')
saveRDS(list(rolling=rolling,ajustes_flex=ajustes_flex),file.path(salida,'modelos_nuevos.rds'))
writeLines(capture.output(sessionInfo()),file.path(salida,'sesion_R.txt'))
mensaje('ANALISIS_RAPIDOS_COMPLETOS')

# Incertidumbre de RMSE y sesgo, sobre las mismas fechas de 2025 y manteniendo
# juntas todas las estaciones de cada bloque, sin reajustar los modelos.
mensaje('Intervalos de las concentraciones')
set.seed(5822)
pg<-read.csv(file.path(revision,'analisis/salidas/cierre/predicciones_gam.csv'))
pg$dia<-as.Date(pg$dia);pg<-filter(pg,escenario=='Log1p')
pc<-filter(base,anio==2025)
pc$estimado_gam<-pg$estimado[match(paste(pc$estacion,pc$dia),paste(pg$estacion,pg$dia))]
pc$estimado_lineal<-NA_real_
for(e in unique(as.character(pc$estacion))){i<-which(pc$estacion==e);pc$estimado_lineal[i]<-predict(lineales[[e]],pc[i,])}
stopifnot(!anyNA(pc$estimado_gam),!anyNA(pc$estimado_lineal))
met_conc<-function(y,p)c(RMSE=sqrt(mean((p-y)^2)),sesgo=mean(p-y))
ci_conc<-list()
for(l in c(7,14)) {
  ids<-indices_bloques(pc,l,2000);bb<-list()
  for(n in c('Lineal','GAM')) {
    p<-pc[[if(n=='Lineal')'estimado_lineal' else 'estimado_gam']]
    b<-t(vapply(ids,function(i)met_conc(pc$O3_max8[i],p[i]),numeric(2)))
    bb[[n]]<-b;est<-met_conc(pc$O3_max8,p)
    ci_conc[[paste(l,n)]]<-bind_rows(lapply(c('RMSE','sesgo'),function(k)
      data.frame(modelo=n,metrica=k,estimacion=est[k],inferior=quantile(b[,k],.025),
        superior=quantile(b[,k],.975),bloque=l,replicas=2000)))
  }
  delta<-bb$GAM[,'RMSE']-bb$Lineal[,'RMSE']
  ci_conc[[paste0(l,'_diferencia')]]<-data.frame(modelo='Diferencia_GAM_Lineal',metrica='RMSE',
    estimacion=met_conc(pc$O3_max8,pc$estimado_gam)['RMSE']-met_conc(pc$O3_max8,pc$estimado_lineal)['RMSE'],
    inferior=quantile(delta,.025),superior=quantile(delta,.975),bloque=l,replicas=2000)
}
guardar(bind_rows(ci_conc),'intervalos_concentraciones')
guardar(pc |> select(estacion,dia,O3_max8,estimado_gam,estimado_lineal),'predicciones_concentraciones_2025')
mensaje('INCERTIDUMBRE_CONCENTRACIONES_COMPLETA')

# Coeficientes del AR(1) en las unidades anteriores a su estandarización.
coef_ar1 <- bind_rows(lapply(c(60,51),function(u){
  m <- ajustes_ar1[[paste(u,2024,sep='_')]]
  v <- c('log_NO_media','log_NO2_media','TOUT_max','SR_media','RH_media','PRS_media','U_media','V_media')
  data.frame(umbral=u,variable=v,beta=glmmTMB::fixef(m$modelo)$cond[v]/m$escala[v])
}))
guardar(coef_ar1,'ar1_coeficientes')
x <- list(base=base,gamm=gamm,formula_gam=form_gam)
vars<-c('log_NO_media','log_NO2_media','TOUT_max','SR_media','RH_media','PRS_media','U_media','V_media','doy_sin','doy_cos','doy_sin2','doy_cos2')
met<-function(y,p,c){z<-p>=c;vp<-sum(z&y==1);fn<-sum(!z&y==1);fp<-sum(z&y==0);vn<-sum(!z&y==0);data.frame(n=length(y),VP=vp,FN=fn,FP=fp,VN=vn,sensibilidad=vp/(vp+fn),precision=vp/(vp+fp),EB=(vp/(vp+fn)+vn/(vn+fp))/2)}
corte<-function(y,p){t<-bind_rows(lapply(seq(0,1,.01),function(c)cbind(corte=c,met(y,p,c))));t<-t[order(-t$EB,-t$sensibilidad,t$corte),];t$corte[1]}
# ajustar_ar1 y predecir_ar1 ya fueron definidos por la sección 10.1 del Rmd.
ar<-read.csv(file.path(revision,'analisis/salidas/cierre/ar1_predicciones.csv'));ar$dia<-as.Date(ar$dia)
res<-list()
for(u in c(60,51)) {
  z<-base;z$evento<-z[[paste0('exc_',u)]]
  limpio<-filter(z,!senalado)
  pp<-list()
  for(y in c(2023,2024)) {
    archivo_m<-file.path(salida,paste0('ar1_calidad_',u,'_',y,'.rds'))
    mensaje(paste('AR1 sin señalados',u,y))
    mod<-if(file.exists(archivo_m))readRDS(archivo_m) else {
      m<-ajustar_ar1(filter(limpio,anio<=y),vars);saveRDS(m,archivo_m,compress=FALSE);m
    }
    # Se omiten también las respuestas marcadas del historial del filtro.
    dz<-filter(limpio,anio<=y+1)
    dz$p<-predecir_ar1(mod,dz)
    pp[[as.character(y+1)]]<-filter(dz,anio==y+1)
  }
  c_l<-corte(pp[['2024']]$evento,pp[['2024']]$p)
  av<-filter(ar,umbral==u,anio==2024);ap<-filter(ar,umbral==u,anio==2025)
  llave<-paste(limpio$estacion,limpio$dia)
  av<-av[paste(av$estacion,av$dia)%in%llave,];ap<-ap[paste(ap$estacion,ap$dia)%in%llave,]
  c_o<-corte(av$evento,av$prob_ar1)
  pe<-pp[['2025']];pe<-pe[match(paste(ap$estacion,ap$dia),paste(pe$estacion,pe$dia)),]
  stopifnot(all(pe$evento==ap$evento),!anyNA(pe$p))
  res[[paste0(u,'_original')]]<-cbind(umbral=u,modelo='AR1_todos',corte=c_o,met(ap$evento,ap$prob_ar1,c_o))
  res[[paste0(u,'_limpio')]]<-cbind(umbral=u,modelo='AR1_sin_senalados',corte=c_l,met(pe$evento,pe$p,c_l))
  guardar(bind_rows(res),'ar1_calidad')
}
mensaje('Sensibilidad del GAMM de CE con ajustes guardados')
# Reajustar un GAMM puede tardar más de una hora. Por defecto se aprovechan
# únicamente ajustes ya calculados. Para pedir nuevos ajustes, ejecutar antes
# options(sima.reajustar_gamm_calidad=TRUE). La regla ampliada no se completó.
reajustar_gamm <- isTRUE(getOption('sima.reajustar_gamm_calidad', FALSE))
ce<-filter(base,estacion=='CE',anio<=2024)
te<-filter(base,estacion=='CE',anio==2025)
ce$tiempo<-as.integer(ce$dia-as.Date('2021-01-01'))
gamms<-list(Todos=x$gamm)
for(regla in c('Inicial','Ampliada')) {
  archivo_m<-file.path(salida,paste0('gamm_calidad_',regla,'.rds'))
  if (!file.exists(archivo_m) && !reajustar_gamm) {
    mensaje(paste('GAMM CE',regla,'omitido: reajuste costoso desactivado'))
    next
  }
  ok<-if(regla=='Inicial')!(ce$revisar_SR|ce$revisar_RH) else !ce$senalado
  mensaje(paste('GAMM CE',regla,'retirados',sum(!ok)))
  gamms[[regla]]<-if(file.exists(archivo_m))readRDS(archivo_m) else {
    m<-mgcv::gamm(x$formula_gam,data=ce[ok,],family=gaussian(),
      correlation=nlme::corAR1(form=~tiempo),method='REML',na.action=na.fail,
      control=nlme::lmeControl(niterEM=0,msMaxIter=200,msMaxEval=400,returnObject=FALSE))
    saveRDS(m,archivo_m);m
  }
  stopifnot(is.list(gamms[[regla]]),inherits(gamms[[regla]]$gam,'gam'))
  eval<-if(regla=='Inicial')!(te$revisar_SR|te$revisar_RH) else !te$senalado
  d<-te[eval,]
  rr<-bind_rows(lapply(c('Todos',regla),function(n){p<-predict(gamms[[n]]$gam,d,type='response');
    data.frame(regla=regla,modelo=n,n_ajuste=if(n=='Todos')nrow(ce) else sum(ok),n_prueba=nrow(d),
      RMSE=sqrt(mean((p-d$O3_max8)^2)),sesgo=mean(p-d$O3_max8))}))
  res[[paste0('GAMM_',regla)]]<-rr
  guardar(bind_rows(res[grepl('GAMM_',names(res))]),'gamm_calidad')
}
mensaje('SENSIBILIDAD_TEMPORAL_COMPLETA')
