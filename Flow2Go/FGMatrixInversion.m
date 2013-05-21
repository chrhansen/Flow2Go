//
//  FGMatrixInversion.m
//  Flow2Go
//
//  Created by Christian Hansen on 30/03/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "FGMatrixInversion.h"

@implementation FGMatrixInversion

/* Inverse of a n by n matrix */
#include<stdio.h>
#include<math.h>


+ (BOOL)isIdentityMatrix:(double **)matrix order:(NSUInteger)order
{
    for(NSUInteger row = 0; row < order; row++)
    {
        for(NSUInteger col = 0; col < order; col++)
        {
            if((row != col && matrix[row][col] != 0.0) // check if off-diag is NOT zero
               || (row == col  && matrix[row][col] != 1.0)) { // check if diag IS zero
                return NO;
            }
        }
    }
    return YES;
}

double determinant(double **a, int k)
{
    double **b = calloc(k * k, sizeof(double *));
    for (NSUInteger i = 0; i < k * k; i++) {
        b[i] = calloc(k * k, sizeof(double));
    }
    double s = 1, det = 0;
    int i, j, m, n, c;
    if (k == 1) {
        for (NSUInteger i = 0; i < k * k; i++)
            free(b[i]);
        free(b);
        return a[0][0];
    } else {
        det = 0;
        for (c = 0; c < k; c++) {
            m = 0;
            n = 0;
            for (i = 0; i < k; i++) {
                for (j = 0; j < k; j++) {
                    b[i][j] = 0;
                    if (i != 0 && j != c) {
                        b[m][n] = a[i][j];
                        if (n < (k - 2))
                            n++;
                        else {
                            n = 0;
                            m++;
                        }
                    }
                }
            }
            det = det + s * (a[0][c] * determinant(b, k - 1));
            s = -1 * s;
        }
    }
    
    for (NSUInteger i = 0; i < k * k; i++)
        free(b[i]);
    free(b);
    return (det);
}

double**  cofactors(double **num, int f)
{
    double **b = calloc(f*f, sizeof(double *));
    double **fac = calloc(f*f, sizeof(double *));
    for (NSUInteger i = 0; i < f*f; i++) {
        b[i] = calloc(f*f, sizeof(double));
        fac[i] = calloc(f*f, sizeof(double));
    }
    int p, q, m, n, i, j;
    for (q = 0; q < f; q++) {
        for (p = 0; p < f; p++) {
            m = 0;
            n = 0;
            for (i = 0; i < f; i++) {
                for (j = 0; j < f; j++) {
                    b[i][j] = 0;
                    if (i != q && j != p) {
                        b[m][n] = num[i][j];
                        if (n < (f - 2))
                            n++;
                        else {
                            n = 0;
                            m++;
                        }
                    }
                }
            }
            fac[q][p] = pow(-1, q + p) * determinant(b, f - 1);
        }
    }
    
    double **transposedMatrix = trans(num, fac, f);
    
    for (NSUInteger i = 0; i < f*f; i++) {
        free(b[i]);
        free(fac[i]);
    }
    free(b);
    free(fac);
    
    return transposedMatrix;
}

double** trans(double **num, double **fac, int n)
{
    int i, j;
    
    double **b = calloc(n*n, sizeof(double *));
    double **inv = calloc(n*n, sizeof(double *));
    for (NSUInteger i = 0; i < n*n; i++) {
        b[i] = calloc(n*n, sizeof(double));
        inv[i] = calloc(n*n, sizeof(double));
    }
    
    double d;
    for (i = 0; i < n; i++) {
        for (j = 0; j < n; j++) {
            b[i][j] = fac[j][i];
        }
    }
    
    d = determinant(num, n);
//    inv[i][j] = 0;
    for (i = 0; i < n; i++) {
        for (j = 0; j < n; j++) {
            inv[i][j] = b[i][j] / d;
        }
    }
    
    
    for (NSUInteger i = 0; i < n * n; i++) {
        free(b[i]);
    }
    free(b);
    
    return inv;
}


+ (double **)getInverseMatrix:(double **)a order:(NSUInteger)n success:(BOOL *)success
{
    double det = determinant(a, n);
    
    if (det == 0.0) {
        *success = NO;
    } else {
        double **inverseMatrix = calloc(n, sizeof(double *));
        for (NSUInteger i = 0; i < n; i++) {
            inverseMatrix[i] = calloc(n, sizeof(double));
        }
        inverseMatrix = cofactors(a, n);
        *success = YES;
        return inverseMatrix;
    }
    return nil;
}

+ (double *)multiplyMatrix:(double **)matrix byVector:(double *)vector order:(NSUInteger)order
{
    double *result = calloc(order, sizeof(double));
    for (int row = 0; row < order; row++) {
        result[row] = 0.0;
        for (int col = 0; col < order; col++) {
            result[col] += matrix[row][col] * vector[col];
        }
    }
    for (int i = 0; i < order; i++) {
        vector[i] = result[i];
    }
    free(result);
    return vector;
}

+ (double *)multiplyVector:(double *)vector byMatrix:(double **)matrix order:(NSUInteger)order
{
    double result[order];
    for (int col = 0; col < order; col++) {
        result[col] = 0.0;
        for (int row = 0; row < order; row++) {
            result[col] +=  vector[row] * matrix[row][col];
        }
    }
    for (int i = 0; i < order; i++) {
        vector[i] = result[i];
    }
    return vector;
}

+ (FGMatrix3)invertAffineTransform2D:(FGMatrix3)matrix isInvertible:(BOOL *)isInvertible
{
    FGMatrix3 invertedTransform;
    double det = fabs( matrix.m00 * matrix.m11 - matrix.m01 * matrix.m10 );
    if (det == 0.0) {
        *isInvertible = NO;
        return invertedTransform;
    }
    FGMatrix3 invertedMatrix;
    *isInvertible = YES;
    //Row 0
    invertedMatrix.m00 =   matrix.m11 / det;
    invertedMatrix.m01 = - matrix.m01 / det;
    invertedMatrix.m02 = ( matrix.m01 * matrix.m12 - matrix.m02 * matrix.m11 ) / det;
    //Row 1
    invertedMatrix.m10 = - matrix.m10 / det;
    invertedMatrix.m11 =   matrix.m00 / det;
    invertedMatrix.m12 = ( matrix.m02 * matrix.m10 - matrix.m00 * matrix.m12 ) / det;
    //Row 2
    invertedMatrix.m20 =   0.0;
    invertedMatrix.m21 =   0.0;
    invertedMatrix.m22 =   1.0;
    
    return invertedMatrix;
}

+ (FGVector3)multiplyMatrix:(FGMatrix3)matrix byVector:(FGVector3)vector
{
    FGVector3 result;
    result.v0 = vector.v0 * matrix.m00  +  vector.v1 * matrix.m01  +  vector.v2 * matrix.m02;
    result.v1 = vector.v0 * matrix.m10  +  vector.v1 * matrix.m11  +  vector.v2 * matrix.m12;
    result.v2 = vector.v0 * matrix.m20  +  vector.v1 * matrix.m21  +  vector.v2 * matrix.m22;
    return result;
}

@end
