import { ExecutionContext, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Observable, isObservable } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  canActivate(
    context: ExecutionContext,
  ): boolean | Promise<boolean> | Observable<boolean> {
    const result = super.canActivate(context);

    if (result instanceof Promise) {
      return result.catch(() => true);
    }

    if (isObservable(result)) {
      return result.pipe(
        map(() => true),
        catchError(() => [true]),
      );
    }

    return result;
  }

  handleRequest<TUser = any>(err: any, user: any): TUser {
    return user;
  }
}
