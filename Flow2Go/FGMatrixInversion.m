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
    double **b = calloc(k * k, sizeof(NSUInteger *));
    for (NSUInteger i = 0; i < k * k; i++) {
        b[i] = calloc(k * k, sizeof(double));
    }
    double s = 1, det = 0;
    int i, j, m, n, c;
    if (k == 1) {
        return (a[0][0]);
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
    double **b = calloc(f*f, sizeof(NSUInteger *));
    double **fac = calloc(f*f, sizeof(NSUInteger *));
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
    
    double **b = calloc(n*n, sizeof(NSUInteger *));
    double **inv = calloc(n*n, sizeof(NSUInteger *));
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
    inv[i][j] = 0;
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
        double **inverseMatrix = calloc(n, sizeof(NSUInteger *));
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
    double result[order];
    for (int row = 0; row < order; row++) {
        result[row] = 0.0;
        for (int col = 0; col < order; col++) {
            result[col] += matrix[row][col] * vector[col];
        }
    }
    for (int i = 0; i < order; i++) {
        vector[i] = result[i];
    }
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

@end
