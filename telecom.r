data <- read.csv("C:\\Users\\1\\Desktop\\选修\\2\\电话\\telecom.csv")
head(data)
dim(data)
str(data)
data <- within(data,{
  SeniorCitizen <- factor(SeniorCitizen, levels = c(0,1), labels = c("No", "Yes"))
  Partner <- factor(Partner)
  Dependents <- factor(Dependents)
})
params <- c("gender", "PhoneService", "MultipleLines", "InternetService", "OnlineSecurity", "OnlineBackup", "DeviceProtection", "TechSupport", "StreamingTV", "StreamingMovies", "Contract", "PaperlessBilling", "PaymentMethod", "Churn")
data[params] <- lapply(data[params],factor)
colSums(is.na(data))
hist(data$TotalCharges, breaks = 50, prob = TRUE, main = "hist of TotalCharges")
median_value <- median(data$TotalCharges, na.rm = TRUE)
data$TotalCharges[is.na(data$TotalCharges)] <- median_value
# colSums(is.na(data))
# for(i in 10:15)
#   {
#     print(xtabs(~ Churn + get(names(data)[i]), data = data))
#   }
levels(data$OnlineSecurity)[2] <- "No"
levels(data$OnlineBackup)[2] <- "No"
levels(data$DeviceProtection)[2] <- "No"
levels(data$TechSupport)[2] <- "No"
levels(data$StreamingTV)[2] <- "No"
levels(data$StreamingMovies)[2] <- "No"
table(data$Churn)
library(ggplot2)
options(digits=4)
ggplot(data, aes(x = "" ,fill = Churn))+
  geom_bar(stat = "count", width = 0.5, position = 'stack')+
  coord_polar(theta = "y", start=0)+
  geom_text(stat="count", 
            aes(label = scales::percent(..count../nrow(data), 0.01)), 
            size=4, position=position_stack(vjust = 0.5)) +
  theme(
    panel.background = element_blank(),
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank())
library(cowplot)
param_1 <- ggplot(data, aes(x = gender, fill = Churn)) + 
  geom_bar(stat = 'count',position = "dodge")
param_2 <- ggplot(data, aes(x = SeniorCitizen, fill = Churn)) + 
  geom_bar(stat = 'count',position = "dodge")
param_3 <- ggplot(data, aes(x = Partner, fill = Churn)) + 
  geom_bar(stat = 'count',position = "dodge")
param_4 <- ggplot(data, aes(x = Dependents, fill = Churn)) + 
  geom_bar(stat = 'count',position = "dodge")
plot_grid(param_1, param_2, param_3, param_4, nrow = 2)
ggplot(data, aes(x = Churn, y = tenure)) + geom_boxplot(aes(fill = Churn))
ggplot(data, aes(x = tenure)) +  geom_bar(fill = "lightblue") + facet_grid(Churn ~ .)
p <- apply(data, 2, function(R){
  
  ggplot(data) + aes(x = R, fill = Churn) + geom_bar(stat = 'count',position = "fill")
})
param_5 <- p['PhoneService']$PhoneService + labs(x = "PhoneService") 
param_6 <- p['MultipleLines']$MultipleLines + labs(x = "MultipleLines")
param_7 <- p['InternetService']$InternetService + labs(x = "InternetService")
param_8 <- p['OnlineSecurity']$OnlineSecurity + labs(x = "OnlineSecurity")
param_9 <- p['OnlineBackup']$OnlineBackup + labs(x = "OnlineBackup")
param_10 <- p['DeviceProtection']$DeviceProtection + labs(x = "DeviceProtection")
param_11 <- p['TechSupport']$TechSupport + labs(x = "TechSupport")
param_12 <- p['StreamingTV']$StreamingTV + labs(x = "StreamingTV")
param_13 <- p['StreamingMovies']$StreamingMovies + labs(x = "StreamingMovies")
plot_grid(param_5, param_6, param_7, param_8, param_9, nrow = 2)
plot_grid(param_10, param_11, param_12, param_13, nrow = 2)
param_14 <- p['Contract']$Contract + labs(x = 'Contract') 
param_15 <- p['PaperlessBilling']$'PaperlessBilling' + labs(x = 'PaperlessBilling')
param_16 <- p['PaymentMethod']$PaymentMethod + labs(x = 'PaymentMethod')
plot_grid(param_14, param_15, param_16, nrow = 3)
ggplot(data, aes(x = Churn, y = MonthlyCharges)) + geom_boxplot(aes(fill = Churn))
param_17 <- ggplot(data, aes(x = MonthlyCharges, fill= Churn, alpha = 0.5)) +
  geom_density()
param_18 <- ggplot(data, aes(x = TotalCharges, fill= Churn, alpha = 0.5)) +
  geom_density()
plot_grid(param_17, param_18, nrow = 2)
set.seed(123)
train <- sample(nrow(data), 0.7*nrow(data))
data.train <- data[train,]
data.test <- data[-train,]
table(data.train$Churn)
table(data.test$Churn)
library(pROC)
prediction <- function(algorithm, prob, test = data.test, n = 2){
  
  pred <- predict(algorithm, data.test, type = "class")
  table <- table(data.test$Churn, pred)
  if(!all(dim(table)==c(2,2)))
    stop("Must be a 2 x 2 table")
  tn = table[1,1]
  fp = table[1,2]
  fn = table[2,1]
  tp = table[2,2]
  accuracy = round((tn+tp)/(tn+fp+fn+tp),n)
  precision = round(tp/(tp+fp),n)
  sensitivity = round(tp/(tp+fn),n)
  specificity = round(tn/(tn+fp),n)
  f1_score = round((2*precision*sensitivity)/(precision+sensitivity),n)
  
  modelroc <- roc(data.test$Churn, prob[,2]) 
  plot(modelroc, print.auc=TRUE, auc.polygon=TRUE,legacy.axes=TRUE,
       grid=c(0.1, 0.2), 
       grid.col=c("green", "red"), max.auc.polygon=TRUE,
       auc.polygon.col="skyblue", print.thres=TRUE)
  auc <- auc(modelroc)
  
  data.frame(accuracy, precision, sensitivity, specificity, f1_score, auc)
}
library(randomForest)
library(caret)
ctrl <- trainControl(
  method = "cv",          
  number = 5,             
  classProbs = TRUE,
  summaryFunction = twoClassSummary
)
rf_cv <- train(
  Churn ~ .,
  data = data.train,
  method = "rf",
  metric = "ROC",
  trControl = ctrl,
  tuneGrid = data.frame(mtry = seq(0, 8, 1))
)

plot(rf_cv)
fit.rf <- randomForest(Churn~., data = data.train, mtry = rf_cv$bestTune$mtry, ntree= 400)
rf.prob <- predict(fit.rf, data.test, type="prob")
# Create a confusion matrix for the predicted and actual values
# table(predict(fit.rf, data.test), data.test$Churn)
prediction(fit.rf, rf.prob, data.test, 2)
library(e1071)
svm_cv <- train(
  Churn ~ .,
  data = data.train,
  method = "svmRadial",  
  metric = "ROC",
  trControl = ctrl,
  tuneLength = 10       
)

plot(svm_cv)
fit.svm <- svm(Churn~., data =data.train, probability=TRUE)
pred.svm <- predict(fit.svm, data.test, probability=TRUE)
svm.prob <- attr(pred.svm, "probabilities")
prediction(fit.svm, svm.prob, data.test, 2)
# names(rf_cv$results)
# names(svm_cv$results)
# print(rf_cv$results$ROC)
# print(svm_cv$results$ROC)
comapre <- resamples(list(
  randomforest = rf_cv,
  SVM = svm_cv
))

bwplot(comapre, metric = "ROC")
dotplot(comapre, metric = "ROC")

summary(comapre)




